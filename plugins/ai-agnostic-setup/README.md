# ai-agnostic-setup

Plugin pro správu AI agnostického prostředí — udržuje soulad mezi **Claude Code**, **Cursor** a **GitHub Copilot** na stejných instrukcích, skills a MCP serverech bez ručního kopírování.

## Co plugin přidá

**Skill `ai-agnostic-setup`** pokrývá:

- Nastavení po klonu — junction na `skills/`, sync MCP konfigurace
- Údržbu kanonu — kde a jak editovat instrukce, skills, MCP servery
- Přidání nového sdíleného MCP serveru
- Přidání nového AI agenta (šablona vstupního souboru)
- Specifika per agent — Claude Code, Cursor, GitHub Copilot
- Diagnostiku — stromový rozhodovací průvodce pro řešení problémů
- Checklist po změně kanonu

**Scripty** (`scripts/`):

| Skript | Účel |
|--------|------|
| `setup-agent-symlinks.ps1` | Vytvoří junction `.claude/skills` → `skills/` a `.cursor/skills` → `skills/` |
| `sync-agent-mcp.ps1` | Zkopíruje `agent/mcp.json` do `.mcp.json` (Claude) a `.cursor/mcp.json` (Cursor) |

## Použití scriptů

### Z vlastního `scripts/` adresáře projektu (doporučeno)

Zkopíruj scripty do `scripts/` svého projektu — pak fungují bez parametrů:

```powershell
.\scripts\setup-agent-symlinks.ps1
.\scripts\sync-agent-mcp.ps1
```

### Přímo z umístění pluginu

Scripty přijímají parametr `-RepoRoot` a lze je spustit odkudkoliv:

```powershell
# po instalaci pluginu přes /plugin
$plugin = ".claude\plugins\ai-agnostic-setup"
& "$plugin\scripts\setup-agent-symlinks.ps1" -RepoRoot (Get-Location)
& "$plugin\scripts\sync-agent-mcp.ps1"      -RepoRoot (Get-Location)
```

## Předpoklady projektu

Projekt musí mít:

```
skills/               ← kanon skills (junction cíl)
agent/
  mcp.json            ← kanon MCP serverů (sync zdroj)
  mcp.local.json      ← osobní MCP (mimo git, volitelné)
```

Env proměnné (PowerShell profil nebo systémové):

| Proměnná | Kdy povinná |
|----------|------------|
| `CONTEXT7_API_KEY` | vždy |
| `YOUTRACK_URL`, `YOUTRACK_TOKEN`, `YOUTRACK_MCP_SERVER_PATH` | jen lokální YouTrack MCP |

## Instalace

```
/plugin install fullsys-plugins ai-agnostic-setup
```
