# YouTrack Fullsys

Plugin pro Fullsys Claude Code Plugin Marketplace, který napojuje Claude na interní **YouTrack Fullsys** ([`https://youtrack.fullsys.cz`](https://youtrack.fullsys.cz)) přes vzdálený MCP server.

## Popis

Plugin nese konfiguraci jednoho HTTP MCP serveru `youtrack`. Konfigurace je v souboru [`.mcp.json`](.mcp.json), na který se odkazuje pole `mcpServers` v manifestu pluginu. Po instalaci Claude získá nástroje pro práci s tickety, projekty, agilními boardy, komentáři, time trackingem a knowledge base YouTracku.

## Instalace

```
/plugin marketplace add fullcom-systems/claude-code-plugins-marketplace
/plugin install youtrack-fullsys@fullsys-plugins
```

## Konfigurace tokenu

Server se autentizuje hlavičkou `Authorization: Bearer <token>`. Token se **nezapisuje do `.mcp.json`** — načítá se z proměnné prostředí `YT_FULLSYS_TOKEN`, kterou `.mcp.json` expanduje (`${YT_FULLSYS_TOKEN}`).

1. Vygenerujte si v YouTracku permanentní token: **Profile → Account Security → Authentication → New token**.
2. Nastavte proměnnou prostředí (PowerShell, trvale pro uživatele):

   ```powershell
   [Environment]::SetEnvironmentVariable("YT_FULLSYS_TOKEN", "<VAS_TOKEN>", "User")
   ```

3. Restartujte Claude Code, aby se proměnná načetla.

> [!IMPORTANT]
> Pokud proměnná `YT_FULLSYS_TOKEN` není nastavená, Claude Code **odmítne načíst konfiguraci MCP serveru** (selže parsování `.mcp.json`) a server `youtrack` se vůbec neaktivuje — nedojde k tichému spuštění s prázdným tokenem. Záměrně zde **není** výchozí hodnota (`${VAR:-default}`): u tajemství je hard failure žádoucí, protože vás okamžitě upozorní na chybějící token místo pozdějších chyb 401. Řešením je nastavit proměnnou podle kroků výše a restartovat Claude Code.

> [!WARNING]
> Token je credential — nikdy ho nevkládejte přímo do `.mcp.json`, do commitů ani do promptů. Při úniku ho okamžitě zneplatněte (rotace tokenu v YouTracku).

## Požadavky

- Claude Code s podporou HTTP MCP serverů
- Síťový přístup na `https://youtrack.fullsys.cz`
- Platný permanentní token YouTracku v proměnné `YT_FULLSYS_TOKEN`

## Bezpečnost

- **Žádné credentials v konfiguraci.** Token se předává výhradně přes proměnnou prostředí, `.mcp.json` obsahuje jen placeholder `${YT_FULLSYS_TOKEN}`.
- Při návrhu integrací s externími systémy platí princip **„no direct outbound calls from skills — use MCP servers"**: skills nemají volat externí služby přímo, veškerý odchozí provoz jde přes tento MCP server.

## Přispívání

Pro přidání vlastního pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
