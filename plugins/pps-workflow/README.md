# pps-workflow

Sada git/PR skillů pro projekty **PPS** (Planning a další .NET/Angular microservices) v **Azure DevOps on-premise** (Škoda). Pokrývá celý workflow od lokálního review přes commit a založení pull requestu až po zapracování review komentářů.

> Určeno pro PPS, **nezávisí** na YouTrack ani na konvencích NextFIS. Pro NextFIS použij pluginy `commit` a `pr`.

## Skilly

| Skill | Invokace | Účel |
|-------|----------|------|
| `commit-pps` | automaticky i `/commit-pps` | Conventional Commits — analyzuje diff, určí type/scope/popis, commitne; s argumentem `push` provede i `git push`. |
| `pr-pps` | jen `/pr-pps` | Vytvoří PR do `dev-sprint` přes Azure CLI — verifikace build/test/lint, JIRA odkaz, ověřovací checklist. |
| `pr-fix-pps` | jen `/pr-fix-pps` | Zapracuje review komentáře z PR — auto-fix SonarQube findings, reviewer komentáře k potvrzení, commit + push. |
| `review-lokalne` | automaticky i `/review-lokalne [repo] [base] [--rozpracovane]` | Lokální code review změny podle `REVIEW.md` repa a pravidel podle změněných cest. Nic nepublikuje. |
| `review-init` | automaticky i `/review-init [repo] [--vystup <cesta>]` | Navrhne `REVIEW.md` pro mikroslužbu — pravidla ověřená v kódu, zkušební review na skutečném PR. Do repa nezapisuje. |

`pr-pps` a `pr-fix-pps` mají `disable-model-invocation: true` — spustí se **pouze** explicitním zavoláním, ne automaticky.

## Workflow

```
review-lokalne  →  commit-pps  →  pr-pps  →  (review)  →  pr-fix-pps
 lokální review     commit         PR                       zapracování připomínek
```

Push je centralizovaný v `commit-pps`: `pr-pps` i `pr-fix-pps` volají `/commit-pps push`, takže logika pushe žije na jednom místě.

## Prerekvizity

Jednorázové nastavení pro `pr-pps` a `pr-fix-pps` (samotné skilly už ho do kontextu neopakují — drží jen odkaz sem).

**1. Azure CLI + rozšíření `azure-devops`**

```bash
# macOS
brew install azure-cli
# Windows (jedna z možností)
winget install --id Microsoft.AzureCLI

az extension add --name azure-devops
```

**2. Personal Access Token**

PAT v env proměnné `AZURE_DEVOPS_EXT_PAT` se scope **Code (Read & Write)** (ten pokrývá i PR a PR thread operace, které volá `pr-fix-pps`). Vytvoříš v Azure DevOps → User Settings → Personal Access Tokens. Nastav v `~/.claude/settings.json` (CC ho načte v každé session):

```json
{
  "env": {
    "AZURE_DEVOPS_EXT_PAT": "<tvůj-token>"
  }
}
```

**Nikdy** token nedávej do souboru v repu.

**3. PowerShell 7 (pro `review-lokalne` a `review-init`)**

Skripty review běží v PowerShell 7 (`pwsh`) na macOS i Windows:

```bash
# macOS
brew install powershell
# Windows
winget install --id Microsoft.PowerShell
```

## Review podle pravidel repa

`review-lokalne` čte kritéria z repa, ne ze sebe: kontrakt `REVIEW.md` v kořeni (závažnost, na co se zaměřit, co nehlásit,
odkazy na `CLAUDE.md`/`AGENTS.md`/pravidla), pravidla s `paths:` a mapu cest na znalostní skilly. Bez `REVIEW.md` dělá
obecné review a nabídne `/review-init`. Formát kontraktu: [`skills/review-lokalne/references/kontrakt-v1.md`](skills/review-lokalne/references/kontrakt-v1.md),
šablona: [`skills/review-init/references/sablona-REVIEW.md`](skills/review-init/references/sablona-REVIEW.md).

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
/review-lokalne planning
/review-lokalne --rozpracovane
/review-init technology
```

## Bezpečnost

- **No direct outbound calls** — veškerá komunikace s Azure DevOps jde přes `az` / `az devops invoke`, nikdy přes `curl`/`wget`.
- `review-lokalne` a `review-init` pracují jen s lokálním gitem (žádné síťové volání) a do repa nic nezapisují.
- Skilly nikdy necommitují secrets a nepoužívají `--force` / `--no-verify` bez explicitního pokynu.
