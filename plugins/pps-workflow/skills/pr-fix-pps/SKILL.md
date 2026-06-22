---
name: pr-fix-pps
description: Načte komentáře z existujícího pull requestu v Azure DevOps (PPS), automaticky opraví SonarQube findings, vypíše reviewer komentáře k potvrzení, vytvoří commit a pushne. Použij vždy, když uživatel chce zapracovat připomínky z PR, opravit Sonar findings nebo "zareagovat na komentáře v PR".
disable-model-invocation: true
---

# Skill: /pr-fix-pps

Globální skill pro zapracování review komentářů z existujícího PR v projektu PPS (Azure DevOps on-premise). Vyžaduje stejné prostředí jako [`pr-pps`](../pr-pps/SKILL.md): **Azure CLI** + rozšíření `azure-devops` a env proměnnou `AZURE_DEVOPS_EXT_PAT` se scope **Code (Read & Write)** — jednorázové nastavení viz [README pluginu](../../README.md#prerekvizity). Pokud `AZURE_DEVOPS_EXT_PAT` chybí nebo PAT nemá scope, `az devops invoke` selže s `TF401019` / `401`.

Cíl: stáhnout aktivní review threads z PR, vyfiltrovat **SonarQube findings** (auto-fix) a **reviewer komentáře** (jen shrnutí k potvrzení), opravit kód, commitnout a pushnout. Označení threads jako resolved skill **neprovádí** — to si dělá uživatel ručně v Azure DevOps UI po review opravy.

## 1. Detekce organization / project / repository

Naparsuj `git remote get-url origin` stejně jako v `pr-pps` (krok 6). Výsledkem musí být:
- `ORG_URL` — např. `https://devops.skoda.vwgroup.com/projects/EOM-7`
- `PROJECT` — např. `PPSToolshop`
- `REPO` — např. `planning`
- `WEB_BASE` — `{ORG_URL}/{PROJECT}/_git/{REPO}` (pro fallback URL)

Pokud parsování selže, zastav.

## 2. Najdi PR podle aktuální větve

Vezmi aktuální větev (`git branch --show-current`) a najdi otevřený PR:

```bash
BRANCH=$(git branch --show-current)
az repos pr list \
  --organization "$ORG_URL" \
  --project "$PROJECT" \
  --repository "$REPO" \
  --source-branch "refs/heads/$BRANCH" \
  --status active \
  --detect false \
  --output json
```

Z výsledku vyber první (a obvykle jediný) PR — jeho `pullRequestId` ulož jako `PR_ID`.

**Override z argumentu**: pokud uživatel zavolal skill s číslem (`/pr-fix-pps 12345`), použij `12345` jako `PR_ID` a krok detekce přeskoč.

**Žádný PR nenalezen**:
- Pokud `git status --porcelain` ukáže necommitované změny → upozorni uživatele, ať nejdřív vytvoří PR přes `/pr-pps`.
- Jinak vypiš: *"K větvi `$BRANCH` neexistuje aktivní PR. Spusť nejdřív `/pr-pps`."* a zastav.

**Více PR**: zobraz seznam (id + title) a zeptej se uživatele, který má použít.

## 3. Načtení review threadů

Pro Azure DevOps REST volání používej **výhradně `az devops invoke`** (princip *no direct outbound calls from skills* — žádný `curl` / `wget`).

```bash
az devops invoke \
  --organization "$ORG_URL" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO" pullRequestId="$PR_ID" \
  --api-version 7.1 \
  --http-method GET \
  --output json
```

Pokud volání vrátí `TF401019` / `404` se zmínkou o `repositoryId`, opakuj s `repositoryId=<GUID>` — GUID získáš z:

```bash
az repos show --repository "$REPO" --project "$PROJECT" --organization "$ORG_URL" --detect false --query id -o tsv
```

## 4. Filtrace threadů

Z `value` v JSON odpovědi zachovej jen:
- `status == "active"` nebo `status == "pending"` (přeskoč `fixed`, `closed`, `wontFix`, `byDesign`)
- `isDeleted != true`
- `comments[]` neprázdné, kde `comments[0].commentType != "system"` (přeskoč systémové eventy typu "iteration update")

Pro každý zbývající thread vyextrahuj:
- `threadId` = `id`
- `filePath` = `threadContext.filePath` (může být `null` → obecný PR komentář)
- `line` = `threadContext.rightFileStart.line` (může být `null`)
- `author` = `comments[0].author.displayName`
- `authorUnique` = `comments[0].author.uniqueName` (e-mail / SPN)
- `content` = `comments[0].content`
- `replies` = `comments[1..]` (může být prázdné)

## 5. Klasifikace: SonarQube vs reviewer

Thread je **SonarQube finding**, pokud platí alespoň jedno:
- `author` (case-insensitive) obsahuje `sonar` (typicky `SonarQube`, `Sonar`, `sonar-bot`)
- `authorUnique` obsahuje `sonar`
- `content` začíná známým prefixem Sonar reportu (`**`, ikona ☂️/⚠️/🔥, nebo obsahuje `sonar` + odkaz na `/dashboard?id=`)

Ostatní threads jsou **reviewer komentáře**.

## 6. Shrnutí pro uživatele

Před opravou vypiš stručný přehled (česky), aby uživatel věděl, co se chystá:

```
PR #<PR_ID>: <title>
<URL>

SonarQube findings (auto-fix): N
- [<filePath>:<line>] <první řádek content> — thread #<threadId>
- ...

Reviewer komentáře (k potvrzení): M
- <author> @ [<filePath>:<line>]: <content excerpt> — thread #<threadId>
- ...
```

Pokud N = 0 a M = 0 → vypiš *"PR nemá žádné aktivní komentáře k zapracování."* a skonči.

## 7. Auto-fix SonarQube findings

Pro každý SonarQube thread:

1. **Načti soubor** (`filePath` je relativní k root repozitáře — odstraň úvodní `/`).
2. **Najdi kontext** kolem `line` (typicky ±10 řádků) — Read tool s `offset`/`limit`.
3. **Vyhodnoť pravidlo** z `content` — Sonar zprávy obsahují název pravidla (`csharpsquid:S1234`, `typescript:S5678`) a popis. Aplikuj odpovídající opravu:
   - **S1186 / "empty method body"** → doplň `throw new NotImplementedException()` nebo odeber metodu.
   - **S125 / "commented out code"** → odeber blok komentářů.
   - **S1481 / "unused local variable"** → odstraň proměnnou.
   - **S2933 / "field readonly"** → přidej `readonly`.
   - **S3776 / "cognitive complexity"** → rozděl metodu (větší zásah → **zeptej se uživatele**).
   - **S107 / "too many parameters"** → vytvoř DTO (větší zásah → **zeptej se uživatele**).
   - **typescript:S6571 / "redundant union"** → odstraň redundantní typ.
   - Neznámé pravidlo → vypiš pravidlo a thread, **zeptej se uživatele** jak postupovat.

4. **Edit** přes standardní `Edit` / `Write` tool — exact string replace, žádné placeholdery.

**Pravidla pro auto-fix**:
- Nikdy nevypínej pravidlo přes `// NOSONAR` ani `[SuppressMessage]` bez explicitního souhlasu uživatele — to je obcházení, ne fix.
- Pokud oprava vyžaduje změnu více než ~20 řádků, **zeptej se** před implementací.
- Pokud Sonar pravidlo není jednoznačně auto-fixovatelné (S3776, S107, design smells), vždy se zeptej.

## 8. Reviewer komentáře

Reviewer komentáře **nezapracovávej automaticky** — jen je vypiš (krok 6 už proběhl) a zeptej se uživatele:

> *"Mám zapracovat i reviewer komentáře? (a = všechny, jednotlivé čísla threadů oddělené čárkou, n = ne)"*

Pokud uživatel řekne ano nebo vybere konkrétní threads, postupuj stejně jako u Sonar (najdi soubor, navrhni změnu, **u každého před editem ukaž návrh** a potvrď).

## 9. Ověření po opravě

Po všech editech detekuj typ projektu a spusť ověření.

### 9a. Backend (.NET) — repozitář obsahuje `*.sln` v rootu

Příklady: `Planning` (Planning.sln), další .NET microservices PPS.

Spusť build:
```bash
dotnet build <Solution>.sln -c Release
```

Spusť testy:
```bash
dotnet test <Solution>.sln
```

Pokud build selže → **zastav**, ukaž chybu a zeptej se uživatele: *"Build po fixu selhal. Chceš revertovat poslední úpravy, opravit ručně, nebo přesto pokračovat s commitem?"*

Pokud testy selžou → stejná otázka pro testy.

### 9b. Frontend (Angular) — repozitář obsahuje `package.json` + `angular.json`

Příklady: `frontend-angular-v2` (Angular ClientApp typicky v `src/FrontendAngular/ClientApp/`).

Najdi adresář s `package.json` (může být v podadresáři, ne v rootu):
```bash
find . -name "package.json" -not -path "*/node_modules/*" -maxdepth 5 | head -5
```

Spusť **lint** v adresáři s `package.json`:
```bash
cd <package-json-dir> && npm run lint
```

Build ani unit testy **na frontendu nespouštěj** — jsou pomalé a běží v CI. Lint stačí jako lokální verifikace.

Pokud lint selže → **zastav**, ukaž chybu a zeptej se uživatele: *"Lint po fixu selhal. Chceš revertovat poslední úpravy, opravit ručně, nebo přesto pokračovat s commitem?"*

### 9c. Žádný `.sln` ani `package.json`

Pokud nepoznáš typ projektu, **zeptej se uživatele**: *"Nepoznal jsem typ projektu (chybí .sln i package.json). Jaké ověření mám spustit?"*

## 10. Commit + push

Spusť skill `/commit-pps push` s commit message zaměřeným na review fixy — provede commit i push v jednom kroku:

```
fix: zapracování review komentářů z PR #<PR_ID>

- <stručný popis Sonar fixů, např. "S1481 unused variable v OrdersQuery">
- <stručný popis reviewer fixů>
```

Pokud push selže (rejected, atd.) → zastav a informuj uživatele.

## 11. Finální report

Vypiš souhrn:

```
✅ Zapracovány komentáře z PR #<PR_ID>: <PR_URL>

Auto-fix SonarQube: K opraveno (z N nalezených)
Reviewer komentáře: L zapracováno (z M nalezených)
Commit: <SHORT_SHA>
Push: ok
```

Připomeň uživateli, ať si v Azure DevOps UI označí vyřešené thready jako **Resolved / Fixed** ručně — skill to schválně nedělá automaticky.

## Chybové stavy (souhrn)

- **`az` chybí / `azure-devops` extension chybí** → instalace stejně jako v [`pr-pps`](../pr-pps/SKILL.md).
- **401 / TF401019** → PAT expiroval nebo nemá scope. PAT potřebuje **Code (Read & Write)** + **Pull Request Threads (Read & Write)**.
- **404 na threadech** → pravděpodobně PR ID neexistuje nebo PAT nevidí repository. Ověř `az repos pr show --id $PR_ID`.
- **Build/test selhal po fixu** → zastav, vrať řízení uživateli, žádné commity ani thread updates.

## Princip "no direct outbound calls from skills"

Všechna komunikace s Azure DevOps probíhá výhradně přes `az` (a `az devops invoke` pro endpointy bez nativního CLI příkazu). Žádné `curl`, `wget`, `Invoke-WebRequest` ani volání REST přes Python skript.
