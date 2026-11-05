## Quick Install Scripts

These scripts create a symbolic link from the Steam Workshop download folder to the Dota 2 vscripts/bots folder. This lets the bot scripts load correctly in Custom Lobbies with **Local Host** server.

### Available Scripts

| File                         | OS      | Language |
| ---------------------------- | ------- | -------- |
| `quick-install-aetherweaver.bat`      | Windows | English  |
| `quick-install-aetherweaver-cn.bat`   | Windows | Chinese  |
| `quick-install-aetherweaver-mac.sh`   | macOS   | English  |
| `quick-install-aetherweaver-linux.sh` | Linux   | English  |

---

## Usage — Windows

1. Place the **vscripts/bots** folder from this repository into your Dota 2 addon folder.
2. Navigate to folder: `Steam\steamapps\workshop\content\570\3246316298\Install-to-vscript`
3. Double-click `quick-install-aetherweaver.bat` to install.

**Finding the folder:** Right-click Dota 2 in your Steam Library → Properties → Installed Files → Browse. This opens `Steam\steamapps\common\dota 2 beta`. In the address bar, replace `common\dota 2 beta` with `workshop\content\570\3246316298\Install-to-vscript` and press Enter.

---

## Usage — macOS

1. Place the **vscripts/bots** folder from this repository into your Dota 2 addon folder.
2. Open Terminal.
3. Navigate to the script folder:
    ```bash
    cd ~/Library/Application\ Support/Steam/steamapps/workshop/content/570/3246316298/Install-to-vscript
    ```
4. Make it executable and run:
    ```bash
    chmod +x quick-install-aetherweaver-mac.sh
    sudo ./quick-install-aetherweaver-mac.sh
    ```

---

## Usage — Linux

1. Place the **vscripts/bots** folder from this repository into your Dota 2 addon folder.
2. Open a terminal.
3. Navigate to the script folder (common Steam locations):
    ```bash
    # Try one of these:
    cd ~/.steam/steam/steamapps/workshop/content/570/3246316298/Install-to-vscript
    cd ~/.local/share/Steam/steamapps/workshop/content/570/3246316298/Install-to-vscript
    ```
4. Make it executable and run:
    ```bash
    chmod +x quick-install-aetherweaver-linux.sh
    sudo ./quick-install-aetherweaver-linux.sh
    ```

The Linux script automatically checks multiple common Steam install locations (`~/.steam/steam`, `~/.local/share/Steam`, `~/.steam/debian-installation`).

---

## How It Works

The script creates a **symbolic link** from this repository's `vscripts/bots` folder to the Dota 2 vscripts directory:

```
Workshop:  Steam/steamapps/workshop/content/570/3246316298
     ↓ (symlink)
Target:    Steam/steamapps/common/dota 2 beta/game/dota/scripts/vscripts/bots
```

Any updates to this repository will automatically appear in the local dev folder.

## Why Is This Needed?

Some players experience issues where bots fail to load correctly. Installing the scripts to the vscripts/bots folder via symlink resolves these issues.

## Uninstall

To uninstall, simply delete the symbolic link in the target folder:

**Windows:**

```cmd
rmdir "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\scripts\vscripts\bots"
```

**macOS:**

```bash
rm ~/Library/Application\ Support/Steam/steamapps/common/dota\ 2\ beta/game/dota/scripts/vscripts/bots
```

**Linux:**

```bash
rm ~/.steam/steam/steamapps/common/dota\ 2\ beta/game/dota/scripts/vscripts/bots
```

This only removes the shortcut — your Workshop subscription and Dota 2 files are not affected.

---

## Troubleshooting

-   **"Steam folder not found"**: Make sure Steam and Dota 2 are installed. If Steam is in a custom location, edit the script and set the path manually.
-   **"Workshop folder not found"**: Place the `vscripts/bots` folder from this repository into your Dota 2 addon folder before running the script.
-   **Permission errors**: Run with administrator privileges (`Run as Administrator` on Windows, `sudo` on Mac/Linux).
-   **Bots still not loading**: Create a Custom Lobby and select **Local Host** as the server location.

For more detailed guides, check the issues in this repository.
