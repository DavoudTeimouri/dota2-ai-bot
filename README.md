# Dota2 AI Bot Workshop Addon

This is a minimal Dota 2 bot addon for the Steam Workshop.
It contains only the required files to be published and run in a custom lobby.
Replace `vscripts/bots/init.lua` with your own bot logic.

## Files
- `addoninfo.txt` – Workshop metadata.
- `vscripts/bots/init.lua` – entry point for the bot (create this file with your Lua code).

## How to Publish
1. Use the Steam Workshop tools (or `steamcmd`) to upload this folder.
2. Set title, description, visibility.
3. After publishing, share the Workshop URL.

## How to Use in Dota 2
1. Subscribe to the Workshop addon.
2. Create a custom lobby in Dota 2 Beta.
3. Enable the addon in the lobby settings.
4. Launch the game; the bot will run `init.lua`.

## License
MIT