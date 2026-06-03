# Docs Architect

Plugin pro Fullsys Claude Code Plugin Marketplace. Přináší skill `docs-architect`, který tvoří a udržuje technickou dokumentaci repozitáře tak, aby byla čitelná pro lidi, nativně funkční v GitHubu a parsovatelná pro RAG/AI. Cílová skupina: vývojáři, kteří píší nebo reorganizují projektovou dokumentaci.

## Obsah

- [Co plugin obsahuje](#co-plugin-obsahuje)
- [Instalace](#instalace)
- [Použití](#použití)
- [Struktura pluginu](#struktura-pluginu)
- [Požadavky](#požadavky)
- [Přispívání](#přispívání)

## Co plugin obsahuje

Jeden skill `docs-architect`, který se aktivuje vždy, když má vzniknout, být aktualizován nebo zreorganizován dokumentační artefakt – README, CONTRIBUTING, CHANGELOG, API specifikace, popis architektury, ADR (Architecture Decision Record), deployment/CI-CD guide, runbook, FAQ či troubleshooting.

Skill stojí na třech pilířích:

1. **AI-friendly struktura** – H1 nadpis + meta-shrnutí jako kotva pro RAG/AI.
2. **Rozcestníky** – vstupní `README.md` slouží jako routing na detailní soubory.
3. **GitHub-friendly formát** – relativní odkazy, tabulky, alert blockquotes, Mermaid diagramy.

Součástí jsou referenční pravidla (`references/`) a šablony dokumentů (`assets/`).

Skill navíc umí dokumentovat **architekturní rozhodnutí formou ADR** ve složce `docs/adr/` – sekvenčně číslované záznamy (`0001-nazev.md`) s kontextem, rozhodnutím, důsledky a zváženými alternativami, životním cyklem přes pole `Status` (Proposed → Accepted → Deprecated / Superseded by ADR-XXXX) a indexem v `README.md`. ADR se nikdy nemažou – superseded záznamy zůstávají v historii.

## Instalace

Nejprve přidejte marketplace (jednorázově) a poté nainstalujte plugin:

```
/plugin marketplace add fullsys/claude-plugin-marketplace
/plugin install docs-architect@fullsys-plugins
```

## Použití

Skill se spouští automaticky podle kontextu. Stačí Claude požádat například:

- „Napiš README pro tento repozitář."
- „Kam v repu dát popis nasazení?"
- „Doplň sekci o autentizaci do API docs."
- „Zdokumentuj rozhodnutí o volbě message brokeru jako ADR."
- „Udělej pořádek v docs složce."

Skill určí cílovou skupinu dokumentu, zařadí ho do správné složky, zvolí odpovídající tón a zapojí ho do rozcestníků.

## Struktura pluginu

```
docs-architect/
  .claude-plugin/plugin.json        ← manifest pluginu
  skills/docs-architect/
    SKILL.md                        ← hlavní instrukce skillu
    references/                     ← pravidla (struktura, formátování, tón)
    assets/                         ← šablony (dokument, README, CONTRIBUTING, CHANGELOG)
  README.md, CHANGELOG.md           ← dokumentace pluginu
```

## Požadavky

- Claude Code s podporou pluginů a skills
- Žádné externí závislosti (skill negeneruje odchozí provoz – „no direct outbound calls from skills")

## Přispívání

Pro přidání nebo úpravu pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
