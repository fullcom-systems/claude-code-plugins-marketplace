# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.0.0] - 2026-07-12

### Added

- Počáteční verze pluginu `dotnet-agentic-loop`
- Skill `setup-agentic-loop` — nastaví v cílovém .NET repu deterministickou agentickou verifikační smyčku (build + testy jako pass/fail gate) přes Claude Code hooks; 7 kroků: analýza projektu → zápis pravidel do `CLAUDE.md` → hook skripty → registrace v `settings.json` → statická analýza (SonarAnalyzer.CSharp) → volitelná monorepo optimalizace → ověření a shrnutí
- Šablony hooků `assets/verify-build.js` (PostToolUse) a `assets/verify-tests.js` (Stop) s placeholdery `{{BUILD_TARGET}}` / `{{TEST_TARGET}}`; Stop hook běží s `dotnet test --no-build` (build zajišťuje PostToolUse hook) a při neaktuálním buildu nebo když `TEST_TARGET` přesahuje `BUILD_TARGET` jednorázově spadne zpět na plný `dotnet test`
- Volitelná integrace context7 (MCP): skill při registraci hooků ověří aktuální schéma Claude Code přes context7, je-li dostupný (jinak elegantně degraduje na vestavěný formát) — v souladu s principem „no direct outbound calls from skills — use MCP servers"
- Zapisovaná sekce v `CLAUDE.md` cílového repa obsahuje i pod-sekci „Aktuální dokumentace (context7)" — instruuje agenta ověřovat aktuální .NET/NuGet API přes context7 (je-li dostupný), čímž se snižuje počet iterací smyčky kvůli halucinovanému API
- `verify-build.js` reportuje i analyzátorové warnings (CA/Sonar/Roslynator…) v editovaném souboru jako neblokující feedback (měkký gate) — statická analýza jako součást build hooku
- Volitelný Krok 5 skillu — přidání Roslyn analyzátoru `SonarAnalyzer.CSharp` (v10.29.0, `PrivateAssets=all`, respektuje Central Package Management) pro shift-left statickou analýzu ve smyčce; bez `-warnaserror`, warnings zůstávají neblokující
- Pravidlo v `CLAUDE.md` cílového repa: analyzátorové warnings z hooku má agent řešit, ne mlčky ignorovat
- Manifest `.claude-plugin/plugin.json`, `README.md`
- Zapracované nálezy z code review (před prvním vydáním): `LOCK_STALE_MS` zvýšen na 660 s (nad nejhorší
  legitimní držení zámku, dřív šlo zámek „ukrást" běžícím testům); Krok 1 — bez nalezených test projektů
  se Stop hook neinstaluje (jinak by gate blokoval každý tah); Krok 6 — změněné soubory se primárně čtou
  z pole `tool_calls_in_turn` Stop payloadu (`.changed-files` jen jako fallback pro starší CLI); Krok 4 —
  ověření přes context7 rozšířeno i na schéma Stop payloadu + zmínka exec form registrace hooků;
  `stop_hook_active` popsán jako pole mimo aktuálně dokumentované schéma (jen defenzivní větev)
