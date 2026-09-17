#!/bin/bash
set -e

echo "Setting up Dota2 AI Bot..."

# Clone framework and addon if not already present (as submodules)
git submodule update --init --recursive

# Determine OS
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    PYTHON_CMD="py -3"
    STEAM_PATH="$HOME/AppData/Local/Steam/steamapps/common/dota 2 beta"
else
    PYTHON_CMD="python3"
    STEAM_PATH="$HOME/.steam/steam/steamapps/common/dota 2 beta"
fi

# Create virtual environment
$PYTHON_CMD -m venv venv
source venv/bin/activate 2>/dev/null || source venv/Scripts/activate

# Install requirements from framework if exists, else use our requirements.txt
if [ -f framework/requirements.txt ]; then
    pip install -r framework/requirements.txt
fi
pip install -r requirements.txt

# Copy addon files to Dota 2 directory
ADDON_NAME="dota2_bot"
ADDON_DEST="$STEAM_PATH/game/dota_addons/$ADDON_NAME"
mkdir -p "$ADDON_DEST/vscripts/bots"
cp -r addon/* "$ADDON_DEST/"
cp vscripts/bots/ability_item_usage_generic.lua "$ADDON_DEST/vscripts/bots/"

# Copy bot file to framework
cp bots/ProBot.py framework/bots/

# Create example settings.py if not present
if [ ! -f framework/settings.py.example ]; then
    cat > framework/settings.py.example << 'EOF'
# Example settings.py for the Dota2 AI Bot
# Copy this file to settings.py and edit as needed

# Bot configuration
bot_filename = "ProBot.py"
bot_classname = "ProBot"

# Optional: adjust how often statistics are collected (seconds)
statistics_collection = 30.0

# Enable debug prints
debug = False
EOF
fi

echo "Setup complete!"
echo "Next steps:"
echo "1. Activate the virtual environment: source venv/bin/activate (or venv\Scripts\activate on Windows)"
echo "2. Edit framework/settings.py (copy from settings.py.example) to set your bot filename and class."
echo "3. Launch a cheat-enabled custom game in Dota 2 Beta."
echo "4. Run: python framework.py"
echo "Enjoy your bot!"