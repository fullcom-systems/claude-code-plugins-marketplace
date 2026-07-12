# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.0.0] - 2026-07-12

### Added

- Počáteční verze pluginu `dotnet-agentic-loop`
- Skill `setup-agentic-loop` — nastaví v cílovém .NET repu deterministickou agentickou verifikační smyčku (build + testy jako pass/fail gate) přes Claude Code hooks; 6 kroků: analýza projektu → zápis pravidel do `CLAUDE.md` → hook skripty → registrace v `settings.json` → volitelná monorepo optimalizace → ověření a shrnutí
- Šablony hooků `assets/verify-build.js` (PostToolUse) a `assets/verify-tests.js` (Stop) s placeholdery `{{BUILD_TARGET}}` / `{{TEST_TARGET}}`; Stop hook běží s `dotnet test --no-build` (build zajišťuje PostToolUse hook) a při neaktuálním buildu nebo když `TEST_TARGET` přesahuje `BUILD_TARGET` jednorázově spadne zpět na plný `dotnet test`
- Manifest `.claude-plugin/plugin.json`, `README.md`
