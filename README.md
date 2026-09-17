# Dota2 AI Bot Workshop Addon

This is a pure Lua bot for Dota 2 that can be published to the Steam Workshop.
No external dependencies, Python, or executables required. Just subscribe to the
addon in Dota 2 and enable it in a custom lobby.

## How to Use

1. Subscribe to the Workshop addon (once published).
2. Create a custom lobby in Dota 2 Beta.
3. Enable the addon in the lobby settings.
4. Launch the game; the bot will auto-join and pick a hero.

## Files

- `addoninfo.txt` – Workshop metadata.
- `vscripts/bots/ability_item_usage_generic.lua` – required stub.
- `vscripts/bots/init.lua` – bot entry point (you can replace with your own logic).

## Publishing to Workshop

1. Use the Steam Workshop tools (or `steamcmd`) to upload the folder.
2. Set the title, description, and visibility.
3. After publishing, share the Workshop URL with others.

## Customizing the Bot

Edit `vscripts/bots/init.lua` to change hero selection, laning, item builds,
ability usage, and chat messages. The file is plain Lua and uses the Dota 2
Scripting API.

## License

MIT