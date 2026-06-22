---
name: pr-pps
description: Vytvoří pull request v Azure DevOps pro projekt Planning/PPS — zkontroluje stav větve, sestaví PR zprávu ze všech commitů oproti dev-sprint, vytvoří PR přes Azure CLI a vrátí odkaz. Spouštěj tento skill pokaždé, když uživatel chce vytvořit pull request, PR, nebo mergovat větev do dev-sprint.
disable-model-invocation: true
---

# Skill: /pr-pps

Globální skill pro vytvoření PR v projektu PPS Planning (Azure DevOps on-premise).

## Prerekvizity

### Azure CLI

Skill používá Azure CLI s rozšířením `azure-devops`:

```bash
brew install azure-cli
az extension add --name azure-devops
```

### Personal Access Token

PAT musí být dostupný jako env proměnná `AZURE_DEVOPS_EXT_PAT` s oprávněním **Code (Read & Write)**.

**V `~/.claude/settings.json`** (doporučeno — CC ho načte automaticky v každé session):
```json
{
  "env": {
    "AZURE_DEVOPS_EXT_PAT": "tvůj-token"
  }
}
```

Token vytvoříš v Azure DevOps → User Settings → Personal Access Tokens → scope **Code (Read & Write)**.

Pokud máš v `settings.json` ještě staré `AZDO_PAT` ze skillu `/pr`, můžeš ho ponechat — `pr-pps` používá výhradně `AZURE_DEVOPS_EXT_PAT` (proměnnou, kterou čte přímo `az`).

## 1. Kontrola stavu větve

Zkontroluj aktuální větev (`git branch --show-current`).

Pokud je aktuální větev `dev-sprint`:
- Zastav a informuj uživatele: "Jsi na dev-sprint. Nejdříve provedu /commit-pps."
- Spusť skill `/commit-pps push`
- Pokud push selže (např. remote není dostupný), informuj uživatele a zastav — nemá smysl volat API.
- Po dokončení pokračuj dál

Zkontroluj, zda existují nějaké commity oproti `dev-sprint`:
```bash
git log dev-sprint..HEAD --oneline
```

Pokud existují necommitované změny (`git status --porcelain`):
- Informuj uživatele: "Na této větvi jsou necommitované změny. Nejdříve provedu /commit-pps."
- Spusť skill `/commit-pps push`
- Pokud push selže, informuj uživatele a zastav
- Po dokončení pokračuj dál

## 2. Ověření kódu (build / testy / lint)

Detekuj typ projektu podle obsahu repozitáře a podle toho zvol ověření:

### 2a. Backend (.NET) — repozitář obsahuje `*.sln` v rootu

Příklady: `Planning` (Planning.sln), další .NET microservices PPS.

Spusť build:
```bash
dotnet build <Solution>.sln -c Release
```

Spusť testy:
```bash
dotnet test <Solution>.sln
```

Zapamatuj si výsledky — počet passed/failed testů pro ověřovací řádky v PR zprávě.

Pokud build selže, **zeptej se uživatele**: "Build selhal. Mám i přesto pokračovat s PR?"
- Pokud ne → zastav
- Pokud ano → pokračuj

Pokud testy selžou, **zeptej se uživatele**: "Některé testy selhaly. Mám i přesto pokračovat s PR?"
- Pokud ne → zastav
- Pokud ano → pokračuj (ověřovací řádek testů bude obsahovat skutečný počet failed)

**Ověřovací řádky pro backend PR zprávu** (krok 4):
```
- [x] Build ověření (0 errors)
- [x] Testy (X passed, 0 failed)
- [x] Přidány testy pro otestování nové funkcionality
```

### 2b. Frontend (Angular) — repozitář obsahuje `package.json` + `angular.json`

Příklady: `frontend-angular-v2` (Angular ClientApp typicky v `src/FrontendAngular/ClientApp/`).

Najdi adresář s `package.json` (může být v podadresáři, ne v rootu):
```bash
find . -name "package.json" -not -path "*/node_modules/*" -maxdepth 5 | head -5
```

Spusť **lint** v adresáři s `package.json`:
```bash
cd <package-json-dir> && npm run lint
```

Build ani unit testy **na frontendu nespouštěj** — jsou pomalé a běží v CI. Lint stačí jako lokální verifikace pro PR.

Pokud lint selže, **zeptej se uživatele**: "Lint selhal. Mám i přesto pokračovat s PR?"
- Pokud ne → zastav
- Pokud ano → pokračuj

**Ověřovací řádky pro frontend PR zprávu** (krok 4):
```
- [x] Lint ověření (0 errors)
- [x] Přidány testy pro otestování nové funkcionality
```
(checkbox "Přidány testy" zaškrtni pouze pokud byly v commitech reálně přidány nové unit/e2e testy)

### 2c. Žádný `.sln` ani `package.json`

Pokud nepoznáš typ projektu, **zeptej se uživatele**: "Nepoznal jsem typ projektu (chybí .sln i package.json). Jaké ověření mám spustit?"

## 3. Zjištění čísla JIRA úkolu

Vezmi číslo úkolu z názvu aktuální větve — větev má formát `<číslo-úkolu>-<název>` nebo `feature/<číslo-úkolu>-<název>`. Příklady:
- `FIE1933-18969-popis-zmeny` → `FIE1933-18969`
- `feature/FIE1933-19551-doplneni-skutecnosti` → `FIE1933-19551`

## 4. Sestavení PR zprávy

Načti všechny commity na větvi oproti `dev-sprint`:
```bash
git log dev-sprint..HEAD --pretty=format:"%s%n%b"
```

Z načtených commitů sestav PR zprávu.

**JIRA odkaz** (1. řádek):
```
**[<číslo-úkolu>](https://jira.skoda.vwgroup.com/browse/<číslo-úkolu>)**
```

**Body** — výcuc ze všech commitů, odrážky popisující konkrétní provedené změny:
```
- <změna 1>
- <změna 2>
- ...
```

**Ověřovací řádky** (na konci, se skutečnými počty z kroku 2) — vyber variantu podle typu projektu:

**Backend (.NET):**
```
- [x] Build ověření (0 errors)
- [x] Testy (X passed, 0 failed)
- [x] Přidány testy pro otestování nové funkcionality
```

**Frontend (Angular):**
```
- [x] Lint ověření (0 errors)
- [x] Přidány testy pro otestování nové funkcionality
```

Checkbox `Přidány testy pro otestování nové funkcionality` zaškrtni pouze pokud byly v commitech reálně přidány nové testy — jinak nech `[ ]`.

### Příklad celé PR zprávy

```
**[FIE1933-18974](https://jira.skoda.vwgroup.com/browse/FIE1933-18974)**

- Rozšíření OrderListModel a OrderList o pole Projects a PartsOfCarType
- Přidání $lookup na batches a partsofcartype v OrdersQuery
- Deduplikace projektů pomocí $setUnion v MongoDB pipeline
- Filtrování podle čísla/názvu projektu a dílu
- Přidání AutoMapper mapování ProjectBaseInfoModel → ProjectBaseInfo

- [x] Build ověření (0 errors)
- [x] Testy (527 passed, 0 failed)
- [x] Přidány testy pro otestování nové funkcionality
```

**Nikdy nepřidávej:**
- Řádek `Co-Authored-By`
- Číslo JIRA úkolu do PR title

## 5. Detekce Azure DevOps organization / project / repository

Načti `git remote get-url origin` a rozparsuj URL:

- **Cloud** `https://dev.azure.com/{org}/{project}/_git/{repo}`:
  - Organization URL = `https://dev.azure.com/{org}`
  - Project = `{project}`
  - Repository = `{repo}`
  - Web base = `https://dev.azure.com/{org}/{project}/_git/{repo}`

- **On-premise Azure DevOps Server** `https://{host}/projects/{collection}/{project}/_git/{repo}` (typický případ pro PPS):
  - Organization URL = `https://{host}/projects/{collection}`
  - Project = `{project}`
  - Repository = `{repo}`
  - Web base = `https://{host}/projects/{collection}/{project}/_git/{repo}`

  Příklad pro PPS Planning:
  - Remote: `https://devops.skoda.vwgroup.com/projects/EOM-7/PPSToolshop/_git/planning`
  - Org URL: `https://devops.skoda.vwgroup.com/projects/EOM-7`
  - Project: `PPSToolshop`
  - Repository: `planning`

- **Legacy visualstudio.com** `https://{org}.visualstudio.com/{project}/_git/{repo}`:
  - Org URL = `https://dev.azure.com/{org}` (nebo `https://{org}.visualstudio.com`)
  - Project, Repo dle URL

- **SSH** `git@ssh.dev.azure.com:v3/{org}/{project}/{repo}`:
  - Org URL = `https://dev.azure.com/{org}`
  - Project, Repo dle URL

Pokud parsování selže, zastav a vypiš chybu.

## 6. Vytvoření PR přes Azure CLI

PR title je popisný název větve (bez čísla JIRA úkolu a bez prefixu `feature/`) — vezmi z názvu větve část za číslem úkolu, nahraď pomlčky mezerami a uprav na čitelný tvar (první písmeno velké).

Příklad: větev `FIE1933-18974-order-list-projects-filter` → title: `Order list projects filter`.

`az repos pr create` má parametr `--description`, který každou předanou hodnotu interpretuje jako nový řádek. Multi-line PR zprávu proto **nepředávej jako jeden string**, ale sestav **bash pole `description_args` řádek po řádku** přímo z PR zprávy z kroku 4 (žádný zápis do souboru v repu):

```bash
description_args=(
  "**[FIE1933-18974](https://jira.skoda.vwgroup.com/browse/FIE1933-18974)**"
  ""
  "- Změna 1"
  "- Změna 2"
  ""
  "- [x] Build ověření (0 errors)"
  "- [x] Testy (527 passed, 0 failed)"
  "- [x] Přidány testy pro otestování nové funkcionality"
)

az repos pr create \
  --organization "<org-url>" \
  --project "<project>" \
  --repository "<repo>" \
  --source-branch "$(git branch --show-current)" \
  --target-branch "dev-sprint" \
  --title "<PR title>" \
  --description "${description_args[@]}" \
  --detect false \
  --output json
```

Vše spusť **v jednom bash volání** (heredoc / `bash -lc`), aby pole `description_args` přežilo do volání `az`.

Pokud některý řádek obsahuje dvojité uvozovky, escapuj je (`\"`).

Z výstupu (JSON) vyber:
- `pullRequestId` → `PR_ID`
- `_links.web.href` → `PR_URL`

Pokud `_links.web.href` chybí, fallback URL sestav jako `<web-base>/pullrequest/<PR_ID>`.

Příklad extrakce přes `jq` (nebo `python3 -c`):
```bash
PR_ID=$(echo "$RESPONSE" | jq -r '.pullRequestId')
PR_URL=$(echo "$RESPONSE" | jq -r '._links.web.href // empty')
```

### Chybová obsluha

- **Chybí `az`** → `command not found: az`: instruuj uživatele, ať nainstaluje Azure CLI (`brew install azure-cli`) a přidá rozšíření (`az extension add --name azure-devops`).
- **Chybí rozšíření azure-devops** → `'repos' is misspelled or not recognized`: `az extension add --name azure-devops`.
- **HTTP 401 / `TF400813` / `TF401019`** → PAT expiroval nebo nemá scope. Informuj uživatele:
  > "Azure CLI vrátilo 401 — PAT pravděpodobně expiroval nebo nemá scope Code (Read & Write). Vygeneruj nový v Azure DevOps → User Settings → Personal Access Tokens a aktualizuj hodnotu `AZURE_DEVOPS_EXT_PAT` v `~/.claude/settings.json`. Pak restartuj CC."
- **`TF401179` (PR už existuje)** → vypiš zprávu a nabídni odkaz na existující PR.
- **Ostatní chyby** → vypiš stderr `az` a sděl uživateli, ať PR vytvoří ručně v Azure DevOps. Vypiš mu připravenou PR zprávu (title + body z kroku 4), ať ji může jen zkopírovat.

## 7. Informuj uživatele

Pokud se PR podařilo vytvořit:
> ✅ PR #<PR_ID> vytvořen: <PR_URL>

Pokud volání selhalo ale push proběhl:
> Push proběhl, ale vytvoření PR přes `az` selhalo. Vytvoř PR ručně v Azure DevOps — zde je připravená zpráva: [vypiš title + body].

## Princip "no direct outbound calls from skills"

Skill volá Azure DevOps **výhradně přes Azure CLI (`az`)** — nikdy ne přímo přes `curl`, `wget` ani jiný HTTP klient. Azure CLI je standardizovaný MCP-like nástroj pro komunikaci se službami Microsoftu a tímto principem se vyhneme nekontrolovanému outbound provozu z prostředí skill.
