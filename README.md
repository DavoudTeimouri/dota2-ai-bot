# Open Hyper AI (OHA) — Dota 2 Bot Scripts

**The most feature-rich custom bot script for Dota 2.** Play against bots that actually fight, farm, push, and use items intelligently.

> **To play:** Create a **Custom Lobby** and select **Local Host** as the server location. Bots should have names ending with **`.OHA`** when installed correctly.

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3246316298) | [GitHub](https://github.com/forest0xia/dota2bot-OpenHyperAI) | [Feature Requests](https://github.com/forest0xia/dota2bot-OpenHyperAI/issues?q=is%3Aissue+is%3Aopen+%5BFeature+request%5D)

---

## What Makes This Different

- **127 heroes supported** on Patch 7.41/7.41a — including Largo, Kez, Ringmaster, Invoker, Techies, Meepo, Lone Druid, and more
- **Bots actually play the game** — they lane, gank, push towers, defend, farm jungle, take Roshan, and use active items
- **Dynamic difficulty (FretBots mode)** — bots get unfair bonuses that scale with difficulty for a real challenge
- **Bots communicate** — they announce pushes, defends, Roshan, and respond to your pings with "On my way!" (in 4 languages)
- **10+ Game modes supported** — All pick, Turbo, All random, Captain mode, 1v1 mid, All Random Deathmatch, etc.
- **Customizable everything** — bot names, roles, hero picks, bans, item builds, skill builds, and more
- **AI Chatbot** — bots chat like real (toxic) players (requires FretBots mode)
- **All roles supported** — deterministic position 1-5 lane assignment

---

## Quick Start

1. Subscribe on [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3246316298)
2. Create a **Custom Lobby** with **Local Host** server
3. Start the game — bots auto-pick and play

For **FretBots mode** (harder bots, neutral items, chatbot): [Manual installation guide](https://github.com/forest0xia/dota2bot-OpenHyperAI/discussions/68)

---

## In-Game Commands

| Command | Description |
|---|---|
| `!pos X` | Swap your role with a bot (e.g., `!pos 2` for mid) |
| `!Xpos Y` | Reassign bot positions (e.g., `!3pos 5` = 3rd bot plays pos 5) |
| `!pick HERO` | Pick a hero (`!pick sniper`, or `/all !pick sniper` for enemy) |
| `!ban HERO` | Ban a hero from being picked |
| `!sp XX` | Set bot language (`en`, `zh`, `ru`, `ja`) |

Use [internal hero names](https://github.com/forest0xia/dota2bot-OpenHyperAI/discussions/71) if short names overlap (e.g., `!pick npc_dota_hero_keeper_of_the_light`). Batch commands work too: `!pick io; !ban sniper`.

---

## Bot Roles & Positioning

Lobby slot order = position assignment (1-5):

| Position | Lane |
|---|---|
| Pos 1 (Carry) + Pos 5 (Hard Support) | Safe Lane |
| Pos 2 (Mid) | Mid Lane |
| Pos 3 (Offlane) + Pos 4 (Soft Support) | Offlane |

Customize picks, bans, and roles in [`Customize/general.lua`](vscripts/bots/Customize/general.lua).

---

## Customization

| What | Where |
|---|---|
| General settings (picks, bans, names, roles) | [`Customize/general.lua`](vscripts/bots/Customize/general.lua) |
| Per-hero settings (items, skills) | [`Customize/hero/viper.lua`](vscripts/bots/Customize/hero/viper.lua) |
| FretBots difficulty tuning | [`FretBots/SettingsDefault.lua`](vscripts/bots/FretBots/SettingsDefault.lua) |

**Permanent customization** (survives Workshop updates): Copy the `Customize` folder to `<Steam/steamapps/common/dota 2 beta/game/dota/scripts/vscripts/game/Customize>`.

---

## Game Modes

Supports most game modes (10+). See [full compatibility discussion](https://github.com/forest0xia/dota2bot-OpenHyperAI/discussions/72).

---

## Offline / LAN Play

You can start a bot game directly from the console without network or clicking UI buttons — useful for offline play, LAN parties, or quick testing. See [play offline setup guide](https://github.com/forest0xia/dota2bot-OpenHyperAI/discussions/135).

---

## Files

```
dota2-ai-bot/
├── vscripts/bots/
│   ├── bot_generic.lua        # Per-bot entry point
│   ├── hero_selection.lua     # Hero picking/banning
│   ├── item_purchase_generic.lua   # Item purchase state machine
│   ├── ability_item_usage_generic.lua # Ability/item active-use for all heroes
│   ├── FretBots.lua           # Enhanced difficulty entry point
│   ├── mode_assemble_generic.lua      # Human ping response
│   ├── mode_attack_generic.lua        # General attacking
│   ├── mode_defend_tower_bot_generic.lua   # Defend bot tower
│   ├── mode_defend_tower_mid_generic.lua   # Defend mid tower
│   ├── mode_defend_tower_top_generic.lua   # Defend top tower
│   ├── mode_farm_generic.lua            # Jungle/creep farming
│   ├── mode_laning_generic.lua          # Early laning, last-hitting
│   ├── mode_outpost_generic.lua         # Outpost control
│   ├── mode_push_tower_bot_generic.lua  # Push bot tower
│   ├── mode_push_tower_mid_generic.lua  # Push mid tower
│   ├── mode_push_tower_top_generic.lua  # Push top tower
│   ├── mode_retreat_generic.lua         # Defensive retreat
│   ├── mode_roam_generic.lua            # Solo ganking
│   ├── mode_roshan_generic.lua          # Roshan hunt
│   ├── mode_rune_generic.lua            # Rune pickup
│   ├── mode_secret_shop_generic.lua     # Secret shop runs
│   ├── mode_side_shop_generic.lua       # Side shop runs
│   ├── mode_team_roam_generic.lua       # Group ganking
│   ├── mode_ward_generic.lua            # Ward placement
│   ├── BotLib/              # 127 per-hero builds (items, skills, ability logic)
│   │   ├── hero_axe.lua, hero_crystal_maiden.lua, ...
│   ├── FunLib/              # Core libraries and utilities
│   │   ├── jmz_func.lua     # Main utility library (IsValid, IsInRange, GetHP, ...)
│   │   ├── aba_item.lua     # Item system (GetItemComponents-based recipes)
│   │   ├── aba_skill.lua    # Skill/ability system (dynamic slot reading)
│   │   ├── aba_role.lua     # Role/position assignment
│   │   ├── aba_ward_utility.lua # Ward spot logic
│   │   ├── spell_list.lua   # Ability weight database (all heroes)
│   │   ├── spell_prob_list.lua   # Ability probability weights
│   │   ├── localization.lua # Chat translations (en/zh/ru/ja)
│   │   └── ... (28 more modules)
│   ├── FretBots/            # Enhanced difficulty mode
│   │   ├── SettingsDefault.lua       # Difficulty tuning
│   │   ├── SettingsNeutralItemTable.lua   # Neutral items + enchantments
│   │   ├── HeroNames.lua      # Hero name localizations
│   │   └── matchups_data.lua         # Hero matchup database
│   ├── Buff/                # Buff mode (enhanced neutral items)
│   │   └── NeutralItems.lua  # Neutral item tier lists + distribution
│   ├── Customize/           # User-editable settings
│   │   ├── general.lua      # Team-level settings (picks, bans, roles)
│   │   └── hero/            # Per-hero overrides
│   ├── ts_libs/             # TypeScript source (compiles to Lua via tstl)
│   │   └── dota/heroes.lua  # HeroName enum
│   └── Install-to-vscript/  # Quick-install scripts for Steam Workshop folder
│       ├── quick-install-oha.bat
│       ├── quick-install-oha-cn.bat
│       ├── quick-install-oha-mac.sh
│       └── quick-install-oha-linux.sh
```

---

## Developer Documentation

| Document | Description |
|---|---|
| [`docs/ARCHITECTURE.md`](https://github.com/forest0xia/dota2bot-OpenHyperAI/blob/main/docs/ARCHITECTURE.md) | Complete codebase architecture, file map, naming conventions, all systems explained |
| [`docs/PATCH_UPDATE_GUIDE.md`](https://github.com/forest0xia/dota2bot-OpenHyperAI/blob/main/docs/PATCH_UPDATE_GUIDE.md) | Step-by-step runbook for updating when a new Dota 2 patch drops |
| [`docs/BOT_API_REFERENCE.md`](https://github.com/forest0xia/dota2bot-OpenHyperAI/blob/main/docs/BOT_API_REFERENCE.md) | Comprehensive Valve bot scripting API reference with examples |

### Internal Name References

Dota 2 bot scripts use internal code names for heroes, items, and abilities — different from in-game display names. Verify against:

| Resource | What It Contains |
|---|---|
| [Liquipedia Cheats (Item Names)](https://liquipedia.net/dota2/Cheats) | Authoritative `item_*` internal names |
| [d2vpkr npc_abilities.txt](https://raw.githubusercontent.com/dotabuff/d2vpk/master/dota_pak01/scripts/npc/npc_abilities.txt) | All ability internal names and KV data |
| [Dota 2 Patch Data API](https://www.dota2.com/datafeed/patchnoteslist?language=english) | Official patch notes, machine-readable |
| [Modifier Names (Valve Wiki)](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/Built-In_Modifier_Names) | `modifier_*` buff/debuff names |

---

## Contribute

- Contributions welcome on [GitHub](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Custom item/skill builds don't need PRs — just tweak locally
- Future development is in **TypeScript** for better maintainability
- [Open feature requests](https://github.com/forest0xia/dota2bot-OpenHyperAI/issues?q=is%3Aissue+is%3Aopen+%5BFeature+request%5D)

---

## What's Next

- Current bot playstyle is limited by Valve's API. **We need ML/LLM bots like OpenAI Five!**
- Planned improvements:
  - Smarter laning, pushing, ganking
  - Stronger spell casting (Invoker, Rubick, Morphling, etc.)
  - Better support for bugged heroes (Dark Willow, IO, Lone Druid, Muerta, etc.)
  - Full game mode support + ongoing patch fixes
- [Feedback to Valve Dota2 bot team](https://www.reddit.com/r/DotA2/comments/1ezxpav/)

---

## Useful Resources

| Resource | Description |
|---|---|
| [Dota2 AI Development Tutorial](https://www.adamqqq.com/ai/dota2-ai-devlopment-tutorial.html) | Comprehensive guide by adamqqq |
| [Valve Bot Scripting Intro](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting) | Official Valve documentation |
| [Lua Bot APIs (moddota)](https://docs.moddota.com/lua_bots/) | Community API docs |
| [Liquipedia Cheats (Internal Names)](https://liquipedia.net/dota2/Cheats) | Item/hero/ability code names |
| [npc_abilities.txt](https://raw.githubusercontent.com/dotabuff/d2vpk/master/dota_pak01/scripts/npc/npc_abilities.txt) | Ability metadata |
| [Enums & APIs (moddota)](https://moddota.com/api/#!/vscripts/dotaunitorder_t) | Enum reference |
| [Modifier Names](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/Built-In_Modifier_Names) | Buff/debuff modifier names |

---

## Support

- Contribute on GitHub
- Or [buy me a coffee](https://github.com/forest0xia/dota2bot-OpenHyperAI/discussions/74)

---

## Credits

Built on top of Valve's default bots + contributions from many talented authors:

- New Beginner AI ([dota2jmz@163.com](mailto:dota2jmz@163.com))
- Tinkering About ([ryndrb](https://github.com/ryndrb/dota2bot))
- Ranked Matchmaking AI ([adamqqq](https://github.com/adamqqqplay/dota2ai))
- fretbots ([fretmute](https://github.com/fretmute/fretbots))
- BOT Experiment (Furiospuppy)
- ExtremePush ([insraq](https://github.com/insraq/dota2bots))
- And all other contributors who made bot games better

---

## License

MIT — see [LICENSE](LICENSE) for details.

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.
