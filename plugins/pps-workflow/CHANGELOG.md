# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.1.3] - 2026-08-19

### Changed

- `commit-pps`: explicitní zákaz trailerů v commit zprávě — `Co-Authored-By`, `🤖 Generated with Claude Code` i jakýkoli další nevyžádaný trailer. Pravidlo je výslovně nadřazené obecným instrukcím prostředí, která trailer `Co-Authored-By` jinak doplňují, a doplněno i do sekce Git Safety Protocol (stejné pravidlo už mělo `pr-pps` pro popis PR)

## [1.1.2] - 2026-08-17

### Fixed

- `pr-pps`: krok 6 vytahuje `pullRequestId` přes `az --query pullRequestId -o tsv` místo `echo "$RESPONSE" | jq`. V zsh (výchozí shell na macOS) `echo` interpretuje escape sekvence, takže validní JSON od `az` rozbilo na neplatný — `"dmz\\DZCX78F"` na `"dmz\DZCX78F"` a `\n` v popisu PR na reálné zalomení řádku — a `jq` skončil s `Invalid escape`. Skill pak uživatele posílal vytvořit PR ručně, přestože PR reálně vznikl

### Changed

- `pr-pps`: nová sekce „Čtení výstupu `az`" — nepoužívat `echo` na JSON (alternativy `--query`, přesměrování do souboru, `printf`), nemergovat stderr do stdout přes `2>&1` kvůli hlášce `WARNING: ... does not support Azure DevOps Server`
- `pr-pps`: URL pull requestu se skládá přímo z `PR_ID` — on-premise Azure DevOps Server pole `_links` v odpovědi nevrací, takže dřívější primární varianta `_links.web.href` nikdy neuspěla
- `pr-pps`: chybová obsluha doplněna o ověření existujících PR na větvi (`az repos pr list --query ...`), aby po nejasné chybě nevznikl duplicitní PR

## [1.1.1] - 2026-08-14

### Fixed

- `commit-pps`: zpřesněn krok vytváření větve z `dev-sprint` — vždy jen prefix `feature/` (i pro `fix:` commity), ošetřen případ, kdy uživatel do zadání sám napíše prefix, a přidáno ověření výsledné větve před commitem

## [1.1.0] - 2026-08-14

### Added

- Frontmatter `model`/`effort` u všech tří skillů — omezuje zbytečnou latenci a spotřebu tokenů dle náročnosti úkolu: `commit-pps` (sonnet, low), `pr-pps` (sonnet, medium), `pr-fix-pps` (opus, high — jediný skill rozhodující o sémantice kódu při auto-fixu Sonar findings)

## [1.0.0] - 2026-06-22

### Added

- Počáteční verze pluginu `pps-workflow`
- Skill `commit-pps` — Conventional Commits pro PPS, větvení z `dev-sprint`, volitelný `push` argument
- Skill `pr-pps` — tvorba pull requestu do `dev-sprint` přes Azure CLI (on-premise Azure DevOps), verifikace build/test/lint, JIRA odkaz; popis PR se předává přes `@file` (UTF-8) a title v ASCII kvůli korektní diakritice na Windows/Git Bash
- Skill `pr-fix-pps` — zapracování review komentářů z PR, auto-fix SonarQube findings, commit + push
- Manifest `.claude-plugin/plugin.json`, `README.md`

### Changed

- Oproti původním lokálním skillům centralizován push do `commit-pps` (`/commit-pps push`); `pr-pps` i `pr-fix-pps` nově volají `/commit-pps push` místo `/commit push`, resp. ručního `git push`
