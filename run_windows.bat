@echo off
setlocal

rem ---- Ensure we are in the repo root ----
cd /d "%~dp0"

rem ---- Paths ----
set "STEAM_PATH=%HOMEPATH%\AppData\Local\Steam\steamapps\common\dota 2 beta"
set "ADDON_NAME=dota2_bot"
set "ADDON_DEST=%STEAM_PATH%\game\dota_addons\%ADDON_NAME%"

rem ---- Create addon folder if missing ->
if not exist "%ADDON_DEST%" (
    mkdir "%ADDON_DEST%"
    echo Created addon folder at %ADDON_DEST%
)

rem ---- Copy addon files (from the repo's addon submodule) ->
xcopy /E /I /Y addon\* "%ADDON_DEST%\"
rem Also copy the Lua stub
xcopy /E /I /Y vscripts\bots\ability_item_usage_generic.lua "%ADDON_DEST%\vscripts\bots\"

rem ---- Copy the built executable (assumes dist\Dota2Bot.exe exists) ->
if exist dist\Dota2Bot.exe (
    copy /Y dist\Dota2Bot.exe "%ADDON_DEST%\Dota2Bot.exe"
    echo Copied executable to addon folder.
) else (
    echo ERROR: dist\Dota2Bot.exe not found. Run build_windows.bat first.
    exit /b 1
)

rem ---- Launch the bot ----
cd /d "%ADDON_DEST%"
start "" Dota2Bot.exe

echo.
echo Bot launched! Check Dota 2 for the bot in your lobby.
echo.
endlocal