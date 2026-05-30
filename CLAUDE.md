# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Co je tento repozitář

Interní plugin marketplace pro Claude — katalog a distribuční bod pro tři typy artefaktů:

- **Pluginy** (`.plugin` soubory = ZIP archivy pro Claude Cowork)
- **MCP servery** (JSON konfigurace)
- **Skills** (`SKILL.md` soubory s instrukcemi pro Claude)

Centrální index je `registry.json`, validovaný proti `schema/registry.schema.json`.

## Skripty

Skripty běží v Bash (Linux/macOS/CI). Na Windows spouštěj přes WSL nebo Git Bash.

```bash
# Validace pluginu (vyžaduje jq, check-jsonschema nebo ajv-cli)
./scripts/validate-plugin.sh plugins/<id>

# Sestavení .plugin archivu → plugins/<id>/dist/<id>-<version>.plugin
./scripts/build-plugin.sh plugins/<id>

# Regenerace registry.json ze všech plugin.json
./scripts/update-registry.sh
```

Závislosti pro skripty: `jq`, `zip`, `check-jsonschema` (`pip install check-jsonschema`) nebo `ajv-cli`.

## Architektura

```
registry.json                  ← strojový index všech pluginů
schema/
  plugin.schema.json           ← JSON Schema pro plugin.json každého pluginu
  registry.schema.json         ← JSON Schema pro registry.json
plugins/<id>/
  plugin.json                  ← metadata (povinné)
  README.md                    ← dokumentace (povinné)
  CHANGELOG.md                 ← Keep a Changelog formát (povinné)
  skills/<skill-id>/SKILL.md   ← YAML frontmatter + instrukce pro Claude
  mcp/                         ← MCP server konfigurace (volitelné)
  dist/                        ← sestavené .plugin soubory (generuje CI)
.github/workflows/
  validate.yml                 ← spouští se při každém PR na main
  release.yml                  ← spouští se při tagu plugins/<id>/v*.*.*
```

### Jak funguje release

Tag ve formátu `plugins/<id>/v<semver>` spustí CI, které:
1. Validuje plugin
2. Sestaví `.plugin` ZIP archiv
3. Vytvoří GitHub Release s archivy jako asset
4. Aktualizuje a commitne `registry.json`

## Konvence

| Oblast | Pravidlo |
|---|---|
| Plugin ID | `^[a-z0-9-]+$` — bez mezer, bez velkých písmen |
| Verze | Striktní semver (`MAJOR.MINOR.PATCH`) |
| Typy pluginu | `skill`, `mcp`, nebo `mixed` |
| SKILL.md | Musí začínat YAML frontmatter (`---`) s poli `name` a `description` |
| JSON soubory | Odsazení 2 mezerami, bez trailing comma |
| Kódování | UTF-8, LF konce řádků (`.gitattributes` to vynucuje) |

## Přidání nového pluginu

1. Vytvořit `plugins/<id>/` podle vzoru `plugins/example-hello-world/`
2. Vyplnit `plugin.json` (validovat proti `schema/plugin.schema.json`)
3. Spustit `./scripts/validate-plugin.sh plugins/<id>`
4. Spustit `./scripts/update-registry.sh` a commitnout změny v `registry.json`
5. Otevřít PR — CI automaticky ověří strukturu a konzistenci registry

## CI workflow

- **`validate.yml`** — při PR detekuje změněné pluginy, validuje každý zvlášť, validuje `registry.json` a kontroluje, zda je aktuální
- **`release.yml`** — parsuje tag `plugins/<id>/v<verze>`, sestaví a publikuje release
