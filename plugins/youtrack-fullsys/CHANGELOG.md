# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.1.0] - 2026-10-08

### Added

- Skill `create-bug-issue` — založení Bugu podle metodiky v KB (FIR-210)
- Skill `create-user-story` — založení User Story podle metodiky v KB (FIR-211)

### Changed

- README: sekce „Popis“ zmiňuje vedle MCP serveru i skilly

## [1.0.1] - 2026-07-14

### Fixed

- Opravena URL příkazu `/plugin marketplace add` v README.md (odkazovala na neexistující `fullsys/claude-plugin-marketplace` místo skutečného repozitáře)

## [1.0.0] - 2026-05-31

### Added

- Počáteční verze pluginu pro napojení na YouTrack Fullsys
- Konfigurace HTTP MCP serveru `youtrack` (`.mcp.json`) s autentizací přes proměnnou prostředí `YT_FULLSYS_TOKEN`
- Manifest `.claude-plugin/plugin.json`
