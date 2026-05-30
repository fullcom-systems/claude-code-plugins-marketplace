# Example MCP Server

Ukázkový plugin pro Fullsys Claude Plugin Marketplace demonstrující **distribuci konfigurace MCP serveru**. Slouží jako referenční šablona pro pluginy s MCP serverem.

## Popis

Plugin nese konfiguraci jednoho MCP serveru `everything` — referenčního testovacího serveru z balíčku [`@modelcontextprotocol/server-everything`](https://github.com/modelcontextprotocol/servers). Konfigurace je v souboru [`.mcp.json`](.mcp.json), na který se odkazuje pole `mcpServers` v manifestu pluginu.

## Instalace

```
/plugin marketplace add fullsys/claude-plugin-marketplace
/plugin install example-mcp@fullsys-plugins
```

## Použití

Po instalaci se MCP server `everything` spustí přes `npx` a zpřístupní Claude sadu testovacích nástrojů (echo, sčítání, dlouhotrvající operace apod.). Ověříte tak, že distribuce MCP konfigurace přes marketplace funguje.

## Požadavky

- Claude Code s podporou MCP serverů
- Node.js a `npx` (server se stahuje a spouští přes `npx -y`)

## Bezpečnost

- **Žádné credentials v konfiguraci.** Connection stringy, API klíče a tokeny se nikdy nezapisují natvrdo do `.mcp.json`. Předávejte je přes proměnné prostředí (pole `env`) nebo přes správu tajemství klienta.
- Tento ukázkový server žádné tajné údaje nevyžaduje (`env` je prázdné).
- Při návrhu integrací s externími systémy platí princip **„no direct outbound calls from skills — use MCP servers"**: skills nemají volat externí služby přímo, veškerý odchozí provoz má jít přes MCP server.

## Přispívání

Tento plugin je referenční šablona MCP pluginu. Pro přidání vlastního pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
