# Fullsys Claude Plugin Marketplace

Interní katalog Claude Code pluginů Fullsys — **skills** a **MCP servery**, distribuované nativně přes Git.

> [!IMPORTANT]
> Tento repozitář je marketplace pro **Claude Code** (příkaz `/plugin`), **nikoli pro Claude Cowork**.
> Pluginy se distribuují **nativně přes Git** — žádné `.plugin` ZIP archivy ani build/release krok.
> Přidáte ho přes `/plugin marketplace add` a instalujete přes `/plugin install`.

## Dostupné pluginy

| Plugin | Typ | Popis |
|---|---|---|
| [docs-architect](plugins/docs-architect/) | skill | Tvorba a údržba technické dokumentace repozitáře (README, CONTRIBUTING, CHANGELOG, API spec, architektura) |
| [repo-architect](plugins/repo-architect/) | skill | Analýza, návrh a oprava struktury složek a souborů GitHub repozitáře dle open-source best-practice standardů |
| [ai-agnostic-setup](plugins/ai-agnostic-setup/) | skill + scripty | Synchronizace instrukcí, skills a MCP serverů mezi Claude Code, Cursor a GitHub Copilot; nastavení po klonu, diagnostika |
| [youtrack-fullsys](plugins/youtrack-fullsys/) | MCP | Napojení na interní YouTrack Fullsys — tickety, projekty, boardy, knowledge base |

## Co obsahuje

| Typ artefaktu | Popis |
|---|---|
| **Skills** | `SKILL.md` soubory s instrukcemi pro Claude (adresář `skills/`) |
| **MCP servery** | Konfigurace MCP serverů (`.mcp.json`) |

Index marketplace je [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Jednotlivé pluginy jsou v adresáři [`plugins/`](plugins/).

## Rychlý start

### Přidání marketplace

V Claude Code:

```
/plugin marketplace add fullsys/claude-plugin-marketplace
```

(nebo URL repozitáře, případně lokální cesta `./plugins-marketplace` pro vývoj).

### Instalace pluginu

```
/plugin install docs-architect@fullsys-plugins
```

Dostupné pluginy zobrazíte přes `/plugin` nebo v [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

### Odinstalace pluginu

```
/plugin uninstall docs-architect
```

Chcete-li odebrat i samotný marketplace (zdrojový repozitář), spusťte:

```
/plugin marketplace remove fullsys-plugins
```

## Jak přidat nový plugin

1. Vytvořte adresář `plugins/<name>/` a zkopírujte strukturu existujícího pluginu jako šablonu.
2. Vyplňte `plugins/<name>/.claude-plugin/plugin.json` (povinné je jen pole `name`).
3. Přidejte komponenty:
   - skills → `skills/<skill-id>/SKILL.md`
   - MCP server → `.mcp.json`
4. Zaregistrujte plugin do [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) (pole `plugins`).
5. Ověřte lokálně a odešlete Pull Request:

   ```bash
   ./scripts/validate-marketplace.sh
   ```

Podrobná pravidla jsou v [CONTRIBUTING.md](CONTRIBUTING.md).

## Struktura repozitáře

```
.claude-plugin/
  marketplace.json              ← index marketplace (povinné)
plugins/<name>/
  .claude-plugin/plugin.json    ← manifest pluginu (povinné)
  skills/<skill-id>/SKILL.md     ← skill (volitelné)
  .mcp.json                      ← MCP servery (volitelné)
  README.md, CHANGELOG.md        ← dokumentace
scripts/
  validate-marketplace.sh        ← validace marketplace a pluginů
.github/workflows/
  validate.yml                   ← CI validace při PR
```

## Validace

```bash
./scripts/validate-marketplace.sh
```

Požadavky: `bash`, `jq`. Na Windows spouštějte přes WSL nebo Git Bash.

## Licence

MIT — viz [LICENSE](LICENSE).
