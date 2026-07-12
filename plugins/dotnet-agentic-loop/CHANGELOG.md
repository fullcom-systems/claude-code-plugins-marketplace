# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.0.0] - 2026-07-12

### Added

- Počáteční verze pluginu `dotnet-agentic-loop`
- Skill `setup-agentic-loop` — nastaví v cílovém .NET repu deterministickou agentickou verifikační smyčku (build + testy jako pass/fail gate) přes Claude Code hooks; 6 kroků: analýza projektu → zápis pravidel do `CLAUDE.md` → hook skripty → registrace v `settings.json` → volitelná monorepo optimalizace → ověření a shrnutí
- Šablony hooků `assets/verify-build.js` (PostToolUse) a `assets/verify-tests.js` (Stop) s placeholdery `{{BUILD_TARGET}}` / `{{TEST_TARGET}}`; Stop hook běží s `dotnet test --no-build` (build zajišťuje PostToolUse hook) a při neaktuálním buildu nebo když `TEST_TARGET` přesahuje `BUILD_TARGET` jednorázově spadne zpět na plný `dotnet test`
- Volitelná integrace context7 (MCP): skill při registraci hooků ověří aktuální schéma Claude Code přes context7, je-li dostupný (jinak elegantně degraduje na vestavěný formát) — v souladu s principem „no direct outbound calls from skills — use MCP servers"
- Zapisovaná sekce v `CLAUDE.md` cílového repa obsahuje i pod-sekci „Aktuální dokumentace (context7)" — instruuje agenta ověřovat aktuální .NET/NuGet API přes context7 (je-li dostupný), čímž se snižuje počet iterací smyčky kvůli halucinovanému API
- Manifest `.claude-plugin/plugin.json`, `README.md`
