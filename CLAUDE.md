# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Co je tento repozitář

Interní **Claude Code plugin marketplace** Fullsys — nativní git-based katalog pluginů.

> Určeno pro **Claude Code** (`/plugin`), **nikoli pro Claude Cowork**. Distribuce probíhá nativně přes Git, ne jako `.plugin` ZIP archivy.

Pluginy nesou:

- **Skills** (`skills/<id>/SKILL.md` — instrukce pro Claude)
- **MCP servery** (`.mcp.json` — konfigurace)

Index marketplace je `.claude-plugin/marketplace.json`.

## Architektura

```
.claude-plugin/
  marketplace.json                  ← index marketplace (name, owner, plugins[])
plugins/<name>/
  .claude-plugin/plugin.json        ← manifest pluginu (povinné pole: name)
  skills/<skill-id>/SKILL.md         ← skill (YAML frontmatter: name, description)
  .mcp.json                          ← MCP servery (volitelné)
  README.md, CHANGELOG.md            ← dokumentace
scripts/
  validate-marketplace.sh            ← validace marketplace + pluginů (bash + jq)
.github/workflows/
  validate.yml                       ← CI validace při PR/push na main
```

## Klíčové principy nativního formátu

- **Distribuce přes Git** — žádné build artefakty ani ZIP archivy. Plugin = adresář v repu.
- **`marketplace.json`** odkazuje na pluginy přes relativní `source` (`./plugins/<name>`).
- **`skills/`** se skenuje automaticky — v `plugin.json` se neuvádí.
- **`commands/`, `agents/`** nahrazují default, pokud jsou v manifestu uvedeny; **`mcpServers`/`hooks`** se merguje.
- Verze: pokud manifest nemá `version`, Claude Code použije commit SHA.

## Skripty

Skripty běží v Bash (Linux/macOS/CI). Na Windows spouštěj přes WSL nebo Git Bash. Závislost: `jq`.

```bash
# Validace celého marketplace a všech pluginů
./scripts/validate-marketplace.sh
```

## Konvence

| Oblast | Pravidlo |
|---|---|
| Název pluginu / skillu | `^[a-z0-9-]+$` — bez mezer, bez velkých písmen |
| `name` v plugin.json | Musí odpovídat názvu adresáře pluginu |
| Verze | Striktní semver (`MAJOR.MINOR.PATCH`) |
| SKILL.md | Musí začínat YAML frontmatterem (`---`) s poli `name` a `description` |
| MCP `.mcp.json` | Standardní MCP formát, **nikdy** credentials (použij `env` / správu tajemství) |
| JSON soubory | Odsazení 2 mezerami, bez trailing comma |
| Kódování | UTF-8, LF konce řádků (`.gitattributes` to vynucuje) |

## Přidání nového pluginu

1. Vytvořit `plugins/<name>/.claude-plugin/plugin.json` podle vzoru `plugins/example-hello-world/` nebo `plugins/example-mcp/`.
2. Přidat komponenty (`skills/`, `.mcp.json`).
3. Zaregistrovat plugin do `.claude-plugin/marketplace.json`.
4. Spustit `./scripts/validate-marketplace.sh`.
5. Otevřít PR — CI automaticky ověří strukturu.

## Odinstalace pluginu

```
/plugin uninstall <name>
```

Pro odebrání celého marketplace (zdrojového repozitáře):

```
/plugin marketplace remove fullsys-plugins
```

## Bezpečnost integrací

Při návrhu integrací s externími systémy platí princip **„no direct outbound calls from skills — use MCP servers"** — skills nevolají externí služby přímo, odchozí provoz jde přes MCP server.
