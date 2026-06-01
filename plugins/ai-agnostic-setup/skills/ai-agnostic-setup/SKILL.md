---
name: ai-agnostic-setup
description: Správa AI agnostického prostředí pro Claude Code, Cursor a GitHub Copilot – nastavení po klonu, aktualizace sdílených instrukcí/skills/MCP, diagnostika, přidání nového agenta.
---

# AI agnostické prostředí

Udržuje shodu tří AI agentů (**Claude Code**, **Cursor**, **GitHub Copilot**) na stejných instrukcích, skills a MCP serverech bez ručního kopírování.

> Detailní architektura: [Doc/ai-agents/sjednoceni.md](../../Doc/ai-agents/sjednoceni.md)

---

## Architektura (jeden zdroj pravdy)

| Vrstva | Kanon (git) | Claude Code | Cursor | GitHub Copilot |
|--------|-------------|-------------|--------|----------------|
| **Instrukce (krátké)** | `AGENTS.md` | `CLAUDE.md` → AGENTS | `.cursorrules` + AGENTS | `.github/copilot-instructions.md` → AGENTS |
| **Instrukce (detail)** | `.cursorrules` | na vyžádání | auto-load | na vyžádání |
| **Skills** | `skills/` | junction `.claude/skills` | junction `.cursor/skills` | čte `skills/` přímo dle instrukce |
| **MCP (sdílené)** | `agent/mcp.json` | `.mcp.json` (sync skript) | `.cursor/mcp.json` (sync skript) | VS Code workspace settings (ruční) |
| **MCP (lokální)** | — | `~/.claude.json` | `~/.cursor/mcp.json` | VS Code user settings |

**Pravidlo údržby:** edituj vždy kanon, nikdy generované soubory. Generované `.mcp.json` a `.cursor/mcp.json` jsou v `.gitignore`.

---

## Nastavení po klonu (všichni vývojáři)

```powershell
# 1. Junction na skills (Cursor + Claude vidí skills/)
.\scripts\setup-agent-symlinks.ps1

# 2. Sync MCP z kanonu do .mcp.json a .cursor/mcp.json
.\scripts\sync-agent-mcp.ps1

# 3. Restart IDE – Cursor: Settings → MCP (zelený stav)
#                  Claude: claude mcp list
```

Env proměnné (PowerShell profil nebo systémové):

| Proměnná | Kdy povinná |
|----------|------------|
| `CONTEXT7_API_KEY` | vždy |
| `YOUTRACK_URL`, `YOUTRACK_TOKEN`, `YOUTRACK_MCP_SERVER_PATH` | jen lokální YouTrack MCP |

---

## Kdy co měnit

| Typ změny | Kde editovat |
|-----------|-------------|
| Nové krátké pravidlo pro všechny agenty | `AGENTS.md` |
| Detailní postup, tabulky, architektura | `.cursorrules` |
| Postup pro konkrétní úkol | `skills/<název>/SKILL.md` (nová podsložka) |
| Nový sdílený MCP server | `agent/mcp.json` → `sync-agent-mcp.ps1` |
| Lokální / per-vývojář MCP | `agent/mcp.local.json` nebo `~/.cursor/mcp.json` |
| Pravidlo jen pro Copilot | `.github/copilot-instructions.md` |
| Pravidlo jen pro Claude | `CLAUDE.md` |
| Modulární pravidlo jen pro Cursor | `.cursor/rules/<název>.md` |

---

## Přidání nového sdíleného MCP serveru

**Kritérium sdíleného kanonu** (obojí musí platit):
- spouštěn přes `npx` bez absolutní lokální cesty
- nevyžaduje osobní token / credential

Postup:

1. Přidej server do `agent/mcp.json`:
   ```json
   "nazev-serveru": {
     "command": "npx",
     "args": ["-y", "@balicek/mcp-server"],
     "env": { "API_KEY": "${NAZEV_PROMENNE}" }
   }
   ```
2. Přidej env proměnnou do tabulky v `CONTRIBUTING.md`.
3. Spusť sync: `.\scripts\sync-agent-mcp.ps1`
4. Pro Copilot: ručně přidej do `.vscode/mcp.json` nebo VS Code user settings (viz sekce Copilot níže).
5. Zaznamenej server do tabulky MCP v `AGENTS.md`.

Pokud server vyžaduje lokální cestu nebo osobní token → patří jen do `agent/mcp.local.json` nebo globálního uživatelského configu.

---

## Přidání nového vstupního souboru (nový agent)

> Tato sekce se používá až při reálné poptávce. Pro Claude, Cursor a Copilot jsou vstupní soubory hotové.

Šablona vstupního souboru (krátký, odkazuje na kanon):

```markdown
# <Název nástroje> – Imatrade / REFIZ

1. Řiď se **[AGENTS.md](AGENTS.md)** – pravidla, skills, MCP.
2. Před úkolem přečti příslušný **`skills/<název>/SKILL.md`** (index: [skills/README.md](skills/README.md)).
3. Detail: **[.cursorrules](.cursorrules)**.

<krátký checklist klíčových pravidel projektu>
```

Po vytvoření vstupního souboru:
- Junction na skills (pokud nástroj podporuje): doplnit do `setup-agent-symlinks.ps1`.
- MCP: doplnit do `sync-agent-mcp.ps1` nebo zdokumentovat ruční postup.
- Aktualizovat mapovací tabulku v `AGENTS.md` a `Doc/ai-agents/sjednoceni.md`.

---

## Specifika per agent

### Claude Code

| Součást | Soubor | Poznámka |
|---------|--------|----------|
| Vstup | `CLAUDE.md` | krátký, odkazuje na AGENTS.md |
| Skills | `.claude/skills` → junction na `skills/` | `setup-agent-symlinks.ps1` |
| MCP (projekt) | `.mcp.json` | generuje `sync-agent-mcp.ps1`; schválit při prvním spuštění |
| MCP (osobní) | `~/.claude.json` | mimo git |
| Detailní pravidla | `.cursorrules` | Claude otevírá na vyžádání |

Ověření:
```powershell
# Junction existuje?
Test-Path ".claude\skills"
# MCP načten?
claude mcp list
```

### Cursor

| Součást | Soubor | Poznámka |
|---------|--------|----------|
| Vstup | `.cursorrules` | auto-load při otevření projektu |
| Modulární pravidla | `.cursor/rules/*.md` | frontmatter `alwaysApply` / `glob` |
| Skills | `.cursor/skills` → junction na `skills/` | `setup-agent-symlinks.ps1` |
| MCP (projekt) | `.cursor/mcp.json` | generuje `sync-agent-mcp.ps1` |
| MCP (osobní) | `~/.cursor/mcp.json` | mimo git; TeamCity, Docker gateway atd. |

Ověření:
```powershell
# Junction existuje?
Test-Path ".cursor\skills"
# MCP config existuje?
Test-Path ".cursor\mcp.json"
# V Cursor UI: Settings → MCP → zelený stav serverů
```

### GitHub Copilot

| Součást | Soubor | Poznámka |
|---------|--------|----------|
| Vstup | `.github/copilot-instructions.md` | auto-load v VS Code s Copilot rozšířením |
| Skills | `skills/` (bez junction) | Copilot čte soubory přímo dle instrukce |
| MCP | VS Code workspace `.vscode/mcp.json` nebo user settings | **není** v `sync-agent-mcp.ps1` – ruční sync |

Ruční sync MCP pro Copilot (`.vscode/mcp.json`):
```json
{
  "servers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": { "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}" }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"]
    }
  }
}
```
> Pokud se `.vscode/mcp.json` přidá do gitu, zkontroluj nejdřív `.gitignore`.

Ověření:
```
VS Code → Command Palette → "GitHub Copilot: Show Agent Instructions" → vidí AGENTS.md?
VS Code → Settings → MCP → servery běží?
```

---

## Diagnostika – agent nezná pravidla / skills

```
Agent ignoruje instrukce?
├── Vstupní soubor existuje? (CLAUDE.md / .cursorrules / copilot-instructions.md)
│   └── NE → vytvoř dle šablony výše
├── Odkazuje vstupní soubor na AGENTS.md?
│   └── NE → doplň odkaz
└── AGENTS.md odkazuje na příslušný SKILL.md?
    └── NE → doplň řádek do tabulky skills v AGENTS.md

Agent nepoužívá skills?
├── Junction existuje? (Test-Path ".claude\skills" / ".cursor\skills")
│   └── NE → spusť setup-agent-symlinks.ps1
├── Příslušný SKILL.md byl přečten před úkolem?
│   └── NE → instrukce v AGENTS.md říká "před úkolem přečti SKILL.md" – agent to musí dodržet
└── Copilot: instrukce říká číst skills/ explicitně?
    └── NE → doplň do .github/copilot-instructions.md

Agent nevidí MCP?
├── .mcp.json / .cursor/mcp.json existuje?
│   └── NE → spusť sync-agent-mcp.ps1
├── Env proměnná CONTEXT7_API_KEY nastavena?
│   └── NE → doplň do PowerShell profilu nebo systémových proměnných
└── IDE bylo restartováno po změně MCP?
    └── NE → restartuj
```

---

## Kontrolní checklist po změně kanonu

Po jakékoli změně v `AGENTS.md`, `skills/`, nebo `agent/mcp.json`:

- [ ] `sync-agent-mcp.ps1` spuštěn (pokud změna MCP)
- [ ] Junction stále platný (`Test-Path ".claude\skills"`, `Test-Path ".cursor\skills"`)
- [ ] Tabulka skills v `AGENTS.md` a `skills/README.md` aktuální
- [ ] Mapovací tabulka v `Doc/ai-agents/sjednoceni.md` aktuální
- [ ] Copilot MCP ručně synchronizován (pokud přibyl/ubyl sdílený server)
- [ ] Commit jen na explicitní žádost; `agent/mcp.local.json`, `.mcp.json`, `.cursor/mcp.json` nejsou v commitu
