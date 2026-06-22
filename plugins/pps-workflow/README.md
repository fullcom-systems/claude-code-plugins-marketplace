# pps-workflow

Sada git/PR skillů pro projekty **PPS** (Planning a další .NET/Angular microservices) v **Azure DevOps on-premise** (Škoda). Pokrývá celý workflow od commitu přes založení pull requestu až po zapracování review komentářů.

> Určeno pro PPS, **nezávisí** na YouTrack ani na konvencích NextFIS. Pro NextFIS použij pluginy `commit` a `pr`.

## Skilly

| Skill | Invokace | Účel |
|-------|----------|------|
| `commit-pps` | automaticky i `/commit-pps` | Conventional Commits — analyzuje diff, určí type/scope/popis, commitne; s argumentem `push` provede i `git push`. |
| `pr-pps` | jen `/pr-pps` | Vytvoří PR do `dev-sprint` přes Azure CLI — verifikace build/test/lint, JIRA odkaz, ověřovací checklist. |
| `pr-fix-pps` | jen `/pr-fix-pps` | Zapracuje review komentáře z PR — auto-fix SonarQube findings, reviewer komentáře k potvrzení, commit + push. |

`pr-pps` a `pr-fix-pps` mají `disable-model-invocation: true` — spustí se **pouze** explicitním zavoláním, ne automaticky.

## Workflow

```
commit-pps  →  pr-pps  →  (review)  →  pr-fix-pps
   commit       PR                       zapracování připomínek
```

Push je centralizovaný v `commit-pps`: `pr-pps` i `pr-fix-pps` volají `/commit-pps push`, takže logika pushe žije na jednom místě.

## Prerekvizity

- **Azure CLI** s rozšířením `azure-devops`:
  ```bash
  brew install azure-cli
  az extension add --name azure-devops
  ```
- **PAT** v env proměnné `AZURE_DEVOPS_EXT_PAT` (scope **Code (Read & Write)**, pro `pr-fix-pps` navíc **Pull Request Threads (Read & Write)**). Nastav v `~/.claude/settings.json` → `env`. **Nikdy** token nedávej do souboru v repu.

## Instalace

```
/plugin install pps-workflow@fullsys-plugins
```

## Příklady použití

```
/commit-pps
/commit-pps push
/pr-pps
/pr-fix-pps
/pr-fix-pps 12345
```

## Bezpečnost

- **No direct outbound calls** — veškerá komunikace s Azure DevOps jde přes `az` / `az devops invoke`, nikdy přes `curl`/`wget`.
- Skilly nikdy necommitují secrets a nepoužívají `--force` / `--no-verify` bez explicitního pokynu.
