@echo off
setlocal

rem ---- Ensure we are in the repo root ----
cd /d "%~dp0"

rem ---- Create/activate a virtual environment if not present ----
if not exist venv (
    python -m venv venv
)
call venv\Scripts\activate

rem ---- Install/upgrade pip and required packages ----
python -m pip install --upgrade pip
pip install -r requirements.txt
if exist framework\requirements.txt (
    pip install -r framework\requirements.txt
)
rem PyInstaller is needed for the build
pip install pyinstaller

rem ---- Build the executable ----
pyinstaller --onefile --name Dota2Bot framework\bots\ProBot.py

rem ---- Inform user ----
echo.
echo Build complete! Executable is at dist\Dota2Bot.exe
echo.
endlocal