# Dota2 Pro Bot

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

## Prerequisites
- Dota 2 Workshop Tools DLC
- Dota 2 Beta (via Steam)
- Python 3.7+

## Setup
1. Clone the framework and addon:
   ```bash
   git clone https://github.com/ellakk/5v5dota2ai-framework
   git clone https://github.com/ellakk/5v5dota2ai-addon
   ```

2. Copy the addon files to your Dota 2 beta game directory:
   ```
   <SteamLibrary>/steamapps/common/dota 2 beta/game/dota_addons/
   ```

3. Place the Lua scripts from `vscripts/` into:
   ```
   <SteamLibrary>/steamapps/common/dota 2 beta/game/dota_addons/your_addon_name/vscripts/
   ```

4. Place the Python bot file (`bots/ProBot.py`) into the framework's `bots/` directory.

5. Edit `settings.py` in the addon to set:
   - `bot_filename = "ProBot.py"`
   - `bot_classname = "ProBot"`

6. Launch a custom game with cheats enabled and run:
   ```bash
   python framework.py
   ```

## Usage
- The bot will auto-join and select a hero.
- Use chat wheel commands via the bot's chat messages.
- Bot sends hints and funny messages to aid human teammates.
- Configure behavior in `ProBot.py` (item builds, skill picks, communication triggers).

## Sharing
- Upload this repository to GitHub.
- Users can clone, follow setup steps, and run the bot in their own Dota 2 custom games.
- Ensure each user has their own Workshop Tools and Python environment.

## License
MIT