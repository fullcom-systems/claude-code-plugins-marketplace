# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.2.0] - 2026-07-15

### Added

- Skill nejprve hledá projektovou PR šablonu (`pull_request_template.md` v `.github/`, `docs/` nebo rootu, case-insensitive); pokud existuje, má přednost před vestavěnou šablonou

### Changed

- Skill `pr` je nyní obecně platný — odstraněny vazby na NextFIS a konkrétní stack (YouTrack URL, `appsettings`/`web.config`, NuGet, formát verze `YY.MM.build.revision`)
- Odkaz na ticket používá placeholder `<issue-tracker-url>` (Jira / YouTrack / GitHub Issues / Azure Boards)
- Verze v šabloně je volitelná; zdroj verze zobecněn (`package.json`, `*.csproj`, `pyproject.toml`, git tag…)
- Položky dopadů a testování zobecněny (závislosti, konfigurace, integrační / API test)
- Skill `pr` detekuje výchozí větev (`main`/`master`) místo napevno zadaného `master`
- Postup vytvoření PR doplněn o push větve a kontrolu, zda PR pro větev už neexistuje

### Removed

- Soubor `EXAMPLE.md` — prázdná šablona a pravidla v `SKILL.md` postačují, vyplněné příklady duplikovaly strukturu šablony

## [1.0.0] - 2026-06-16

### Added

- Počáteční verze pluginu `pr`
- Skill `pr` pro vytváření pull requestů dle šablony PR
- Referenční příklady v `skills/pr/EXAMPLE.md`
- Manifest `.claude-plugin/plugin.json`
