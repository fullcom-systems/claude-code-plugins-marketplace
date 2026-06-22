# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.0.0] - 2026-06-22

### Added

- Počáteční verze pluginu `pps-workflow`
- Skill `commit-pps` — Conventional Commits pro PPS, větvení z `dev-sprint`, volitelný `push` argument
- Skill `pr-pps` — tvorba pull requestu do `dev-sprint` přes Azure CLI (on-premise Azure DevOps), verifikace build/test/lint, JIRA odkaz
- Skill `pr-fix-pps` — zapracování review komentářů z PR, auto-fix SonarQube findings, commit + push
- Manifest `.claude-plugin/plugin.json`, `README.md`

### Changed

- Oproti původním lokálním skillům centralizován push do `commit-pps` (`/commit-pps push`); `pr-pps` i `pr-fix-pps` nově volají `/commit-pps push` místo `/commit push`, resp. ručního `git push`
