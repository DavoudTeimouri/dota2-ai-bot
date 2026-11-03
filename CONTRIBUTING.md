# Contributing to Open Hyper AI (OHA)

Thank you for considering contributing to Open Hyper AI!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Custom item/skill builds don't need PRs — just tweak locally in `Customize/hero/`.

## Code Style

- Follow existing Lua patterns in `bots/` and `bots/FunLib/`
- Keep functions small and focused
- Add comments for complex logic
- Use `GetItemComponents()` for item recipes — don't hardcode component arrays
- Use `sAbilityList[N]` references when possible — resilient to ability renames
- Test in Dota 2 custom lobby before submitting

## Reporting Issues

Use the GitHub issue tracker. Include:
- Dota 2 version
- Steps to reproduce
- Expected vs actual behavior
- Any console errors

## Patch Updates

When a new Dota 2 patch drops, follow the runbook in
[docs/PATCH_UPDATE_GUIDE.md](https://github.com/forest0xia/dota2bot-OpenHyperAI/blob/main/docs/PATCH_UPDATE_GUIDE.md):
items -> hero builds -> abilities -> neutrals -> actives -> map changes.
Always verify ability names on Liquipedia before trusting patch note summaries.

## License

By contributing, you agree your contributions will be licensed under the MIT License.
