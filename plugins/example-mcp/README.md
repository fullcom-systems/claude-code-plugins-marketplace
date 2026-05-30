# Example MCP Server

Ukázkový plugin pro Claude Plugin Marketplace demonstrující **distribuci konfigurace MCP serveru**. Slouží jako referenční šablona pro pluginy typu `mcp`.

## Popis

Plugin nese konfiguraci jednoho MCP serveru `everything` — referenčního testovacího serveru z balíčku [`@modelcontextprotocol/server-everything`](https://github.com/modelcontextprotocol/servers). Konfigurace je v souboru [`mcp/everything.json`](mcp/everything.json) a v `plugin.json` je na ni odkaz přes pole `mcpServers[].config`.

## Instalace

1. Stáhněte soubor `example-mcp-1.0.0.plugin` z [GitHub Releases](https://github.com/fullsys/claude-plugin-marketplace/releases) nebo sestavte lokálně:

   ```bash
   ./scripts/build-plugin.sh plugins/example-mcp
   ```

2. V Claude Cowork naimportujte `.plugin` soubor přes dialog pro instalaci pluginů.

3. Alternativně přidejte obsah `mcp/everything.json` do své MCP konfigurace pod klíč serveru `everything`.

## Použití

Po instalaci se MCP server `everything` spustí přes `npx` a zpřístupní Claude sadu testovacích nástrojů (echo, sčítání, dlouhotrvající operace apod.). Ověříte tak, že distribuce MCP konfigurace přes marketplace funguje.

## Požadavky

- Claude Cowork s podporou MCP serverů
- Node.js a `npx` (server se stahuje a spouští přes `npx -y`)

## Bezpečnost

- **Žádné credentials v konfiguraci.** Connection stringy, API klíče a tokeny se nikdy nezapisují natvrdo do `mcp/*.json`. Předávejte je přes proměnné prostředí (pole `env`) nebo přes správu tajemství klienta.
- Tento ukázkový server žádné tajné údaje nevyžaduje (`env` je prázdné).
- Při návrhu integrací s externími systémy platí princip **„no direct outbound calls from skills — use MCP servers"**: skills nemají volat externí služby přímo, veškerý odchozí provoz má jít přes MCP server.

## Přispívání

Tento plugin je referenční šablona. Pro přidání vlastního MCP pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
