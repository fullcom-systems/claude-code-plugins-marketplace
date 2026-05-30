# Claude Plugin Marketplace

Interní katalog a distribuční bod pro Claude Cowork pluginy, MCP server konfigurace a Skills.

## Co obsahuje

| Typ artefaktu | Popis |
|---|---|
| **Pluginy** (`.plugin`) | ZIP archivy pro Claude Cowork |
| **MCP servery** | JSON konfigurace vzdálených/lokálních serverů |
| **Skills** | `SKILL.md` soubory s instrukcemi pro Claude |

Hlavní index všech pluginů je v souboru [`registry.json`](registry.json).

## Rychlý start

### Instalace pluginu

1. Najděte plugin v [`registry.json`](registry.json) nebo v adresáři [`plugins/`](plugins/).
2. Stáhněte `.plugin` soubor z [GitHub Releases](https://github.com/fullsys/claude-plugin-marketplace/releases) nebo sestavte lokálně:

   ```bash
   ./scripts/build-plugin.sh plugins/example-hello-world
   ```

3. V Claude Cowork naimportujte `.plugin` soubor.

### Ověření funkčnosti

Spusťte ukázkový plugin a napište `hello world` — skill zobrazí diagnostické informace.

## Jak přidat nový plugin

1. Vytvořte adresář `plugins/<id>/` podle šablony [`plugins/example-hello-world/`](plugins/example-hello-world/).
2. Vyplňte povinné soubory: `plugin.json`, `README.md`, `CHANGELOG.md`.
3. Spusťte validaci:

   ```bash
   ./scripts/validate-plugin.sh plugins/<id>
   ```

4. Aktualizujte registry:

   ```bash
   ./scripts/update-registry.sh
   ```

5. Odešlete Pull Request — CI automaticky ověří strukturu a konzistenci registry.

Podrobná pravidla jsou v [CONTRIBUTING.md](CONTRIBUTING.md).

## Skripty

| Skript | Popis |
|---|---|
| [`scripts/validate-plugin.sh`](scripts/validate-plugin.sh) | Validace pluginu proti JSON schématu |
| [`scripts/build-plugin.sh`](scripts/build-plugin.sh) | Sestavení `.plugin` ZIP archivu |
| [`scripts/update-registry.sh`](scripts/update-registry.sh) | Regenerace `registry.json` |

### Požadavky

- `bash`
- `jq`
- `zip`
- `check-jsonschema` nebo `ajv-cli` (pro validaci)

## Release

Plugin se vydává tagem ve formátu `plugins/<id>/v<verze>`:

```bash
git tag plugins/example-hello-world/v1.0.0
git push origin plugins/example-hello-world/v1.0.0
```

CI automaticky sestaví `.plugin` soubor, vytvoří GitHub Release a aktualizuje `registry.json`.

## Licence

MIT — viz [LICENSE](LICENSE).
