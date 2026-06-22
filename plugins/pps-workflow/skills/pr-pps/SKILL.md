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
# macOS
brew install azure-cli
# Windows (jedna z možností)
winget install --id Microsoft.AzureCLI

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

Příklady: `Planning` (Planning.sln), `Economics` (Economics.sln), další .NET microservices PPS.

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

Popis PR **předávej přes soubor (`@file`), ne přes argumenty.** Na **Windows + Git Bash (MSYS2)** se diakritika předaná v argv komolí na `�` (konverze argv mezi MSYS2 a nativním Windows `az`/Python). Spolehlivé napříč OS je zapsat PR zprávu do dočasného UTF-8 souboru **mimo repozitář** a předat ji přes `@<cesta>` — `az` ho přečte jako UTF-8.

1. Zapiš celou PR zprávu z kroku 4 do dočasného UTF-8 souboru **mimo repo** (UTF-8 **bez BOM**), např. `"${TMPDIR:-/tmp}/pps_pr_desc.txt"` (macOS/Linux) nebo `"$TEMP/pps_pr_desc.txt"` (Windows). Obsah = JIRA odkaz + odrážky + ověřovací řádky. **Žádný zápis do repa.**

2. **Title drž v ASCII** (bez diakritiky) — title se předává v argv, kde by se na Windows rozsypal. Názvy větví jsou stejně ASCII, takže to vychází přirozeně.

3. Vytvoř PR a popis předej přes `@<cesta>`:

```bash
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 az repos pr create \
  --organization "<org-url>" \
  --project "<project>" \
  --repository "<repo>" \
  --source-branch "$(git branch --show-current)" \
  --target-branch "dev-sprint" \
  --title "<PR title v ASCII>" \
  --description @"<cesta-k-souboru>" \
  --detect false \
  --output json
```

`--description @soubor` načte celý obsah souboru jako jeden multi-line popis (zalomení řádků zůstanou zachována) — tím se úplně obejde předávání textu v argumentech a diakritika zůstane v pořádku. (`@file` je standardní konvence Azure CLI pro načtení hodnoty parametru ze souboru.)

Z výstupu (JSON) vyber:
- `pullRequestId` → `PR_ID`
- `_links.web.href` → `PR_URL`

Pokud `_links.web.href` chybí, fallback URL sestav jako `<web-base>/pullrequest/<PR_ID>`.

```bash
PR_ID=$(echo "$RESPONSE" | jq -r '.pullRequestId')
PR_URL=$(echo "$RESPONSE" | jq -r '._links.web.href // empty')
[ -z "$PR_URL" ] && PR_URL="<web-base>/pullrequest/$PR_ID"
```

(Volitelně po dokončení dočasný soubor smaž.)

### Kódování / Windows (proč `@file` a ASCII title)

- `az` je Python CLI. Na **Windows + Git Bash (MSYS2)** se **non-ASCII znaky předané jako argumenty rozsypou** (`�`) — týká se `--title` i `--description`, pokud text jde přímo v argv. Korupce nastává **před** Pythonem (konverze argv při `CreateProcess`), takže ji `PYTHONUTF8` sám neopraví — proto popis přes `@file` a title v ASCII. `PYTHONUTF8`/`PYTHONIOENCODING` jen zajistí, že `az` přečte soubor a vytiskne výstup jako UTF-8.
- **ASCII text projde všude** — na macOS/Linuxu (celá cesta UTF-8) ani u popisů bez diakritiky problém nevzniká.
- **Pozor na ověřování:** `az` na Windows komolí i vlastní **výstup**, takže `az repos pr show ...` může diakritiku zobrazit jako `�`, i když je na serveru uložená správně. Pro jistotu, jak popis vypadá, **otevři PR v prohlížeči** — konzolový výstup `az` v tomhle není spolehlivý.

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
