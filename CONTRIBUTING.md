# Přispívání do Plugin Marketplace

Děkujeme za zájem o rozšíření katalogu pluginů. Tento dokument popisuje pravidla a postup pro přidání nebo aktualizaci pluginu.

## Požadavky

- Git
- Bash
- `jq`, `zip`
- `check-jsonschema` (doporučeno) nebo `ajv-cli`

Instalace validátoru:

```bash
pip install check-jsonschema
```

## Struktura pluginu

Každý plugin musí mít tuto minimální strukturu:

```
plugins/<id>/
├── plugin.json       # Metadata (povinné)
├── README.md         # Dokumentace pro uživatele (povinné)
├── CHANGELOG.md      # Historie verzí (povinné)
├── skills/           # Skills (volitelné)
│   └── <skill-id>/
│       └── SKILL.md
├── mcp/              # MCP konfigurace (volitelné)
└── dist/             # Sestavené .plugin soubory (generované CI)
```

## Konvence

| Oblast | Pravidlo |
|---|---|
| Plugin ID | Pouze `[a-z0-9-]`, bez mezer |
| Verze | Striktní semver (`MAJOR.MINOR.PATCH`) |
| Kódování | UTF-8, LF konce řádků |
| JSON | Odsazení 2 mezerami, bez trailing comma |
| SKILL.md | YAML frontmatter s `name` a `description` |
| Typy pluginu | `skill`, `mcp`, nebo `mixed` |

## MCP servery

Plugin typu `mcp` (nebo `mixed`) deklaruje MCP servery v poli `mcpServers` v `plugin.json`:

```json
"mcpServers": [
  {
    "id": "everything",
    "name": "Everything (demo) MCP Server",
    "description": "Krátký popis serveru.",
    "transport": "stdio",
    "config": "mcp/everything.json"
  }
]
```

- `id` — `[a-z0-9-]`, unikátní v rámci pluginu.
- `transport` — `stdio`, `sse` nebo `http`.
- `config` — cesta ke konfiguračnímu JSON souboru serveru, typicky `mcp/<id>.json`. Validace ověří, že soubor existuje a je validní JSON.

**Bezpečnost:** do `mcp/*.json` nikdy nezapisujte credentials (connection stringy, API klíče, tokeny). Předávejte je přes proměnné prostředí (pole `env`) nebo přes správu tajemství klienta. Platí princip **„no direct outbound calls from skills — use MCP servers"** — odchozí volání patří do MCP serveru, ne do skillu.

Referenční šablonu najdete v [`plugins/example-mcp/`](plugins/example-mcp/).

## Postup pro nový plugin

1. **Fork a větev** — vytvořte feature větev z `main`.

2. **Zkopírujte šablonu** — použijte `plugins/example-hello-world/` jako výchozí bod.

3. **Vyplňte metadata** — upravte `plugin.json` dle [`schema/plugin.schema.json`](schema/plugin.schema.json).

4. **Dokumentace** — README musí obsahovat sekce: Popis, Instalace, Použití, Požadavky, Přispívání.

5. **Changelog** — zaznamenejte změny dle [Keep a Changelog](https://keepachangelog.com/cs/).

6. **Validace lokálně**:

   ```bash
   ./scripts/validate-plugin.sh plugins/<id>
   ./scripts/update-registry.sh
   git diff registry.json   # ověřte, že registry je aktuální
   ```

7. **Pull Request** — CI spustí validaci automaticky.

## Pull Request checklist

- [ ] `plugin.json` prochází validací proti schématu
- [ ] Všechny cesty v `skills[].path` existují
- [ ] Všechny cesty v `mcpServers[].config` existují a jsou validní JSON (bez credentials)
- [ ] README.md a CHANGELOG.md jsou kompletní
- [ ] `registry.json` je aktuální (spuštěn `update-registry.sh`)
- [ ] Plugin ID je unikátní v rámci repozitáře

## Verzování a release

- Verze se mění v `plugin.json` a `CHANGELOG.md`.
- Release se spouští tagem: `plugins/<id>/v<verze>`.
- CI sestaví `.plugin` archiv a publikuje GitHub Release.

## Code review

Každý PR projde review týmem. Kontrolujeme:

- Dodržení schématu a konvencí
- Kvalitu dokumentace
- Bezpečnost MCP konfigurací (pokud jsou přítomny)
- Funkčnost skills

## Otázky

Pro dotazy otevřete issue v repozitáři nebo kontaktujte maintainery.
