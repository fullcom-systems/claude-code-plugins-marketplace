# YouTrack Fullsys

Plugin pro Fullsys Claude Code Plugin Marketplace, který napojuje Claude na interní **YouTrack Fullsys** ([`https://youtrack.fullsys.cz`](https://youtrack.fullsys.cz)) přes vzdálený MCP server.

## Popis

Plugin nese konfiguraci jednoho HTTP MCP serveru `youtrack`. Konfigurace je v souboru [`.mcp.json`](.mcp.json), na který se odkazuje pole `mcpServers` v manifestu pluginu. Po instalaci Claude získá nástroje pro práci s tickety, projekty, agilními boardy, komentáři, time trackingem a knowledge base YouTracku.

## Skilly

Skilly pro zakládání issue v YouTracku Fullsys. Skill obsahuje jen tenké instrukce; pravidla, šablona
a příklady jsou v knowledge base YouTracku a skill si je načte při každém spuštění.

| Skill | Výsledek | Metodika v KB |
| --- | --- | --- |
| `/youtrack-fullsys:create-bug-issue` | issue `Bug` ve stavu `Open` | QA: Zakládání Bugu (pro AI agenta) |
| `/youtrack-fullsys:create-user-story` | issue `User Story` ve stavu `Open` | QA: Zakládání User Story (pro AI agenta) |

```
/youtrack-fullsys:create-bug-issue
/youtrack-fullsys:create-bug-issue customer-12345 hlásí, že terminál při naskladnění hlásí „Šarže je povinná“, HD-00000
/youtrack-fullsys:create-user-story Skladníci chtějí na terminálu dělit palety
```

Skilly volejte s prefixem pluginu (`youtrack-fullsys:`), aby se nezaměnily se stejně pojmenovanými
skilly jiných pluginů.

Agent se doptá na chybějící údaje, dohledá související issue, ukáže draft a issue založí až po potvrzení.
K založení issue potřebujete práva zakládat issue v cílovém projektu.

Pravidla se mění v knowledge base, ne v tomto pluginu. Podněty zapisujte do komentáře článku
*QA: Zakládání issue v YouTracku (pro AI agenta)*.

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
