# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.0.1] - 2026-06-03

### Changed

- Aktualizován popis skillu (`description` ve frontmatteru SKILL.md a v manifestu) dle pravidel pro description v CONTRIBUTING.md

## [1.0.0] - 2026-06-01

### Added

- Počáteční verze pluginu `ai-agnostic-setup`
- Skill `ai-agnostic-setup` pro synchronizaci instrukcí, skills a MCP serverů mezi Claude Code, Cursor a GitHub Copilot
- Skripty `scripts/setup-agent-symlinks.ps1` a `scripts/sync-agent-mcp.ps1`
- Manifest `.claude-plugin/plugin.json`
