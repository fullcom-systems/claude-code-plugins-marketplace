# Přispívání do Plugin Marketplace

Děkujeme za zájem o rozšíření katalogu pluginů. Tento dokument popisuje pravidla a postup pro přidání nebo aktualizaci Claude Code pluginu.

> [!NOTE]
> Pluginy zde jsou pro **Claude Code** (`/plugin`), **ne pro Claude Cowork**. Žádné `.plugin` archivy — plugin je adresář v repu distribuovaný přes Git.

## Požadavky

- Git
- Bash, `jq` (pro lokální validaci; na Windows přes WSL nebo Git Bash)

## Struktura pluginu

Každý plugin má tuto strukturu:

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json     # Manifest pluginu (povinné, povinné je jen pole "name")
├── skills/             # Skills (volitelné) — skenuje se automaticky
│   └── <skill-id>/
│       └── SKILL.md
├── .mcp.json           # MCP servery (volitelné)
├── README.md           # Dokumentace pro uživatele
└── CHANGELOG.md        # Historie verzí
```

### Manifest `plugin.json`

```json
{
  "name": "muj-plugin",
  "description": "Stručný popis pluginu.",
  "version": "1.0.0",
  "author": { "name": "Fullsys", "email": "tym@fullsys.cz" },
  "license": "MIT",
  "keywords": ["kategorie"],
  "mcpServers": "./.mcp.json"
}
```

- `name` — jediné povinné pole, `[a-z0-9-]`, musí odpovídat názvu adresáře pluginu.
- `skills` se NEuvádí — adresář `skills/` se skenuje automaticky.
- `mcpServers` — cesta ke konfiguraci MCP serverů (default `.mcp.json`).

### Skills

Soubor `skills/<skill-id>/SKILL.md` musí začínat YAML frontmatterem s poli `name` a `description`:

```markdown
---
name: skill-id
description: Kdy a k čemu se skill aktivuje.
---

Instrukce pro Claude…
```

### MCP servery

Konfigurace v `.mcp.json` používá standardní formát MCP:

```json
{
  "mcpServers": {
    "muj-server": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {}
    }
  }
}
```

**Bezpečnost:** do `.mcp.json` nikdy nezapisujte credentials (connection stringy, API klíče, tokeny). Předávejte je přes proměnné prostředí (pole `env`) nebo přes správu tajemství klienta. Platí princip **„no direct outbound calls from skills — use MCP servers"** — odchozí volání patří do MCP serveru, ne do skillu.

## Konvence

| Oblast | Pravidlo |
|---|---|
| Název pluginu / skillu | Pouze `[a-z0-9-]`, bez mezer |
| Verze | Striktní semver (`MAJOR.MINOR.PATCH`) |
| Kódování | UTF-8, LF konce řádků |
| JSON | Odsazení 2 mezerami, bez trailing comma |

## Postup pro nový plugin

1. **Větev** — vytvořte feature větev z `main`.
2. **Zkopírujte šablonu** — `plugins/example-hello-world/` (skill) nebo `plugins/example-mcp/` (MCP).
3. **Vyplňte manifest** — `.claude-plugin/plugin.json`.
4. **Komponenty** — skills do `skills/`, MCP do `.mcp.json`.
5. **Registrace** — přidejte plugin do `.claude-plugin/marketplace.json` (pole `plugins`).
6. **Dokumentace** — README a CHANGELOG ([Keep a Changelog](https://keepachangelog.com/cs/)).
7. **Validace lokálně**:

   ```bash
   ./scripts/validate-marketplace.sh
   ```

8. **Pull Request** — CI spustí validaci automaticky.

## Pull Request checklist

- [ ] `plugins/<name>/.claude-plugin/plugin.json` obsahuje pole `name` shodné s názvem adresáře
- [ ] Plugin je zaregistrován v `.claude-plugin/marketplace.json`
- [ ] Skills mají frontmatter s `name` a `description`
- [ ] `.mcp.json` je validní JSON a neobsahuje credentials
- [ ] `./scripts/validate-marketplace.sh` prochází
- [ ] README.md a CHANGELOG.md jsou aktuální

## Code review

Každý PR projde review týmem. Kontrolujeme:

- Dodržení struktury a konvencí
- Kvalitu dokumentace
- Bezpečnost MCP konfigurací (žádné credentials)
- Funkčnost skills

## Otázky

Pro dotazy otevřete issue v repozitáři nebo kontaktujte maintainery.
