# Dota2 Pro Bot

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7%2B-blue.svg)](https://www.python.org/downloads/)

A smart Dota 2 bot that plays like TI professionals, communicates via chat wheel and messages, hints to human players, and works as a team worker.

## Features
- Hero selection & drafting (auto-pick/ban)
- Lane management (last-hit, deny, equilibrium)
- Farming (jungle creep clearing, wave management)
- Dynamic item purchase based on game state
- Smart ability usage & combo execution
- Ganking & roaming with enemy tracking
- Team fighting (target selection, positioning)
- Retreat & defense mechanisms
- Roshan & rune control
- Ward placement for vision
- Courier management
- Chat wheel integration & funny messages
- Hint system for human teammates
- Teamwork-focused behavior

## Quick Start

| Step | Command |
|------|---------|
| 1. Clone repo (with submodules) | `git clone --recurse-submodules https://github.com/DavoudTeimouri/dota2-ai-bot.git` |
| 2. Run setup | `chmod +x setup.sh && ./setup.sh` |
| 3. Activate venv | `source venv/bin/activate` (Linux/macOS) <br> `venv\Scripts\activate` (Windows) |
| 4. Edit settings | Copy `framework/settings.py.example` to `framework/settings.py` and adjust if needed |
| 5. Launch Dota 2 Beta | Create a cheat-enabled lobby, launch the game |
| 6. Run the bot | `python framework.py` |

## Prerequisites
- Dota 2 Workshop Tools DLC
- Dota 2 Beta (via Steam)
- Python 3.7+

## Setup Details
1. **Clone the repository** (this will also clone the required framework and addon as submodules).
2. **Run the setup script** (`setup.sh`). It will:
   - Initialize submodules (framework and addon)
   - Create a Python virtual environment
   - Install required Python packages
   - Copy the addon files to your Dota 2 directory (under `dota2_bot`)
   - Copy the bot script to the framework
   - Provide an example `settings.py`
3. **Configure the bot** by editing `framework/settings.py` (see example below).
4. **Launch a custom game** in Dota 2 Beta with cheats enabled, sv_cheats 1.
5. **Run the bot** from the repository root: `python framework.py`.

## File Layout
```
dota2-ai-bot/
├── framework/           # 5v5dota2ai-framework (submodule)
│   ├── bots/            # Place your bot Python files here
│   └── settings.py      # Bot configuration (create from example)
├── addon/               # 5v5dota2ai-addon (submodule)
│   └── ...              # Files to be copied to Dota 2 addon folder
├── vscripts/
│   └── bots/
│       └── ability_item_usage_generic.lua  # Lua stub required by framework
├── setup.sh             # Automated setup script
├── requirements.txt     # Additional Python requirements
└── README.md
```

## Example settings.py
Create `framework/settings.py` with the following content:
```python
# Bot configuration
bot_filename = "ProBot.py"
bot_classname = "ProBot"

# Optional: adjust how often statistics are collected (seconds)
statistics_collection = 30.0

# Enable debug prints
debug = False
```

## Usage
- The bot will auto-join and select a hero in the lobby.
- It sends periodic chat messages (e.g., greetings, hints) to aid teammates.
- Customize behavior by editing `framework/bots/ProBot.py` (item builds, skill picks, communication triggers).

## Sharing
- Upload this repository to GitHub (already done at https://github.com/DavoudTeimouri/dota2-ai-bot).
- Users can clone with submodules, run `setup.sh`, and follow the steps above.
- Ensure each user has their own Workshop Tools and Python environment.

## Troubleshooting
- **ModuleNotFoundError**: Make sure the virtual environment is activated and dependencies are installed.
- **Lua script errors**: Verify the Lua files are correctly placed in `<SteamPath>/game/dota_addons/dota2_bot/vscripts/bots/`.
- **Bot not joining**: Check that `settings.py` points to the correct bot filename and class, and that the lobby has cheats enabled.

## License
MIT

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.