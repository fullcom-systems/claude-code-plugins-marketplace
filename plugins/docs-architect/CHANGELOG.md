# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.1.2] - 2026-07-14

### Fixed

- Opravena URL příkazu `/plugin marketplace add` v README.md (odkazovala na neexistující `fullsys/claude-plugin-marketplace` místo skutečného repozitáře)

## [1.1.1] - 2026-06-03

### Changed

- Aktualizován popis skillu (`description` ve frontmatteru SKILL.md a v manifestu) dle pravidel pro description v CONTRIBUTING.md

## [1.1.0] - 2026-06-03

### Added

- Podpora ADR (Architecture Decision Records) ve složce `docs/adr/`
- Referenční pravidla `references/adr.md` (struktura záznamu, sekvenční číslování, životní cyklus Proposed → Accepted → Deprecated / Superseded, index v README.md)
- Šablona `assets/adr-template.md` (kontext, rozhodnutí, důsledky, zvážené alternativy)
- Workflow pro ADR v SKILL.md a `docs/adr/` v závazné struktuře repozitáře

## [1.0.0] - 2026-05-30

### Added

- Počáteční verze pluginu `docs-architect`
- Skill `docs-architect` pro tvorbu a údržbu technické dokumentace
- Referenční pravidla v `references/` (struktura repozitáře, formátování, tone of voice)
- Šablony dokumentů v `assets/` (obecný dokument, README, CONTRIBUTING, CHANGELOG)
- Manifest `.claude-plugin/plugin.json`
