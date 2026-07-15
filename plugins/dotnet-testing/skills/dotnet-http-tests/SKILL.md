---
name: dotnet-http-tests
description: >-
  Použij, když uživatel chce „vytvořit .http testy", „REST Client testy",
  „httpyac", „API testy pro .NET", „integrační testy endpointů", „environment
  switching v .http testech" nebo „CI/CD pipeline pro HTTP/API testy" (Azure
  DevOps i GitHub Actions) — i když jen popíše potřebu otestovat REST endpoint
  a zmíní VS Code / REST Client. Skill nejprve zjistí, co repozitář a jeho CI
  už používají, a teprve poté navrhne strukturu `.http` souborů, environment
  soubory, assert bloky a pipeline. Nepoužívej pro unit testy tříd/metod —
  k tomu slouží skill dotnet-unit-tests.
---

# HTTP / API testy pro .NET projekty

Skill pro návrh a údržbu **`.http` testů** v .NET repozitáři — s přepínáním environmentů
(local/staging/prod) a spouštěním v CI/CD přes **httpyac CLI**. Formát je kompatibilní napříč
**VS Code REST Client**, **httpyac** i **IntelliJ HTTP Client**, takže stejné soubory slouží
vývojáři lokálně i pipeline v CI.

Firma provozuje CI **souběžně na Azure DevOps i GitHubu** (podle repozitáře), proto skill umí
vygenerovat pipeline pro obě platformy — detaily v rozcestníku na konci.

Jako sourozenec skillu `dotnet-unit-tests` v tomto pluginu se řídí stejným principem: **nejdřív
zjisti konvence repozitáře**, teprve pak generuj. Nevynucuj konvence jednoho projektu tam, kde
už repozitář nějaké má.

## Kdy použít

Kdykoli uživatel řeší testování HTTP endpointů .NET aplikace, konkrétně když zmíní:

- „.http soubory", „REST Client testy", „httpyac"
- „API testy pro .NET", „integrační testy endpointů"
- „environment switching v .http testech"
- „CI/CD pro HTTP testy", „pipeline pro API testy" (Azure DevOps i GitHub)
- i jen popis potřeby otestovat endpoint + zmínku o VS Code / REST Clientu

Pro **unit testy** tříd a metod (ne HTTP volání) použij místo toho skill `dotnet-unit-tests`.

## Krok 0 — zjisti konvence repozitáře (vždy jako první)

Než cokoli vygeneruješ, ověř v repozitáři:

1. **Existující `.http` soubory** — `Get-ChildItem -Recurse -Filter *.http`. Zjisti, kam je
   repo dává (vedle projektu, `http/`, `tests/http/`) a jak pojmenovává requesty.
2. **Environment soubory** — existuje `http-client.env.json` / `http-client.private.env.json`?
   Jaké environmenty jsou definované a jak se jmenují proměnné (`baseUrl`, `host`, `token`…)?
3. **Runner** — je v repu `httpyac` (v `package.json`, `.httpyac.js`, `httpyac.config.js`),
   nebo jen VS Code REST Client bez CLI? CI runner pro `.http` je vždy **httpyac CLI**.
4. **CI platforma** — má repo `.azure-pipelines/` / `azure-pipelines.yml` (Azure DevOps), nebo
   `.github/workflows/` (GitHub Actions), nebo obojí? Podle toho vyber referenci (viz níže).
5. **`.gitignore`** — je `http-client.private.env.json` (a `.env`) už ignorovaný?

Zjištěné konvence **mají přednost** před výchozími hodnotami tohoto skillu — nové soubory mají
vypadat, jako by je psal někdo, kdo repo zná.

## Postup

1. **Proveď krok 0.**
2. **Vyber CI platformu.** Pokud z repa (krok 0, bod 4) není jednoznačná, **zeptej se**:
   Azure DevOps / GitHub Actions / obojí. Podle odpovědi otevři příslušnou referenci.
3. **Navrhni adresářovou strukturu** `.http` souborů (viz níže).
4. **Vygeneruj / uprav env soubory** — `http-client.env.json` (commitovaný) a šablonu
   `http-client.private.env.json` (gitignored).
5. **Napiš / doplň `.http` requesty** s proměnnými a assert bloky (syntaxe → `SYNTAX.md`,
   ukázkové soubory → `EXAMPLE.md`).
6. **Vygeneruj CI konfiguraci** dle vybrané platformy (jeden nebo oba reference soubory).
7. **Shrň bezpečnostní doporučení** (secrets, `.gitignore`) — viz závěr.

## Adresářová struktura

Jeden `.http` soubor na **doménu / kontroler**, requesty oddělené `###`:

```
http/
├── http-client.env.json            # commitovaný, BEZ secretů
├── http-client.private.env.json    # gitignored, lokální dev override
├── customers.http                  # /api/customers
├── orders.http                     # /api/orders
└── warehouse.http                  # /api/warehouse
```

Konkrétní kořen (`http/`, `tests/http/`, vedle projektu) **přebírej z repozitáře**; výše je
výchozí volba pro repo, které ještě žádnou strukturu nemá.

## Environment soubory

Formát `http-client.env.json` je objekt `{ "<env>": { "<proměnná>": "<hodnota>" } }` — rozumí
mu REST Client, httpyac i IntelliJ HTTP Client. Přepínání environmentu v CI je pak jen
`-e <env>`.

**Dvě vrstvy proměnných — klíč k bezpečnosti:**

| Vrstva | Kam patří | Příklad |
|--------|-----------|---------|
| **Ne-secret** (base URL, ne-citlivé ID) | `http-client.env.json` — **commitovaný** | `baseUrl` |
| **Secret** (token, heslo, klíč) | **nikdy** natvrdo v commitovaném souboru | `token` |

Secret hodnoty se v commitovaném `http-client.env.json` řeší jen jako **odkaz** na proces env
proměnnou — `{{$processEnv API_TOKEN}}` (příp. `{{$dotenv API_TOKEN}}`), ne zapsáním hodnoty.
Takový `token` **není** secret. Skutečná hodnota přijde:

- **lokálně** z `http-client.private.env.json` (gitignored, přepíše hodnotu z commitovaného souboru),
- **v CI** z pipeline secret / variable group injektované jako env proměnná `API_TOKEN`
  (viz reference dané platformy).

Kompletní sada obou souborů (commitovaný `http-client.env.json` + gitignored
`http-client.private.env.json`) je v `EXAMPLE.md`.

> Do commitovaných souborů nikdy nepiš reálné tokeny, hesla, PII ani interní hostnames s
> citlivým významem — jen placeholdery (`<API_TOKEN>`, `https://api.example.internal`).

## Assert bloky — ověření odpovědí

Každý request, který **ověřuje CI**, musí mít assert — jinak httpyac request jen odešle a nemá
co reportovat (v JUnit se neobjeví jako test). Čistě manuální / ad-hoc requesty assert mít nemusí.

httpyac nabízí **dvě syntaxe** (skill akceptuje obě, lze je i míchat v jednom souboru):

- **Deklarativní asserce `??`** — **preferováno** pro běžné kontroly stavu, těla a hlaviček
  (`?? status == 200`, `?? body == true`). Jeden řádek na podmínku.
- **Skriptovací blok `> {% client.test(...) %}`** — pro složitější logiku (výpočty, iterace nad
  polem, předání hodnoty dalšímu requestu přes `client.global.set`).

Base URL i token zapisuj **vždy přes proměnné** (`{{baseUrl}}`/`{{token}}` nebo
`{{host}}`/`{{apiKey}}`), nikdy hardcoded. Requesty odděluj `###`.

Podrobnou syntaxi obou variant (tabulky předmětů, operátorů a predikátů, vlastnosti skriptovacího
bloku, kdy je assert povinný) najdeš v `SYNTAX.md`; kompletní ukázkové `.http` soubory (scénáře
200/400/401, předání tokenu z loginu) v `EXAMPLE.md`.

## Spuštění v CI — společný příkaz

Na obou platformách běží testy stejným příkazem:

```bash
httpyac send "<glob>" --all -e <env> --bail --junit
```

| Volba | Význam | Proč výchozí |
|-------|--------|--------------|
| `"<glob>"` | které soubory spustit, např. `"http/**/*.http"` | pokryje celou složku |
| `--all` | spustí **všechny** requesty v souboru (bez ní jen první) | testy jsou celé soubory |
| `-e <env>` | vybraný environment z `http-client.env.json` | přepínání local/staging/prod |
| `--bail` | zastaví na první selhané asserci | rychlá zpětná vazba, kratší běh |
| `--junit` | výstup ve formátu **JUnit XML** (na stdout) | čitelné pro publikaci výsledků |

`--junit` píše XML na **stdout** → v pipeline se přesměruje do souboru
(`… --junit > junit-report.xml`), který pak publikuje krok pro test results.

**Kompromisy, na které upozorni, pokud se od defaultů odchyluješ:**

- Bez `--bail` doběhnou **všechny** testy (vidíš všechny chyby najednou), ale běh je delší a při
  fail-fast politice to není žádoucí. Pro nightly „full" běh může dávat smysl `--bail` vynechat.
- Chceš-li čistý JUnit XML bez těla odpovědí v logu, přidej `-o none`.
- `-e` musí odpovídat názvu klíče v `http-client.env.json`; v CI ho typicky nastav podle větve
  (staging pro `develop`, prod jen ručně / na tag).

## CI/CD — výběr platformy (rozcestník)

Podle platformy zjištěné v kroku 0 (nebo potvrzené uživatelem) otevři:

- **Azure DevOps** → [`references/azure-devops.md`](references/azure-devops.md) — YAML pipeline
  (`NodeTool@0` + httpyac + `PublishTestResults@2` s JUnit), secrets přes variable groups.
- **GitHub Actions** → [`references/github-actions.md`](references/github-actions.md) — workflow
  (`actions/setup-node` + httpyac + `dorny/test-reporter` nebo JUnit artifact), secrets přes
  GitHub Actions secrets.

Pokud uživatel potřebuje **obojí**, vygeneruj oba soubory se stejnou sadou environmentů a
stejným httpyac příkazem.

## Bezpečnost (závazné)

- **Žádné secrety v commitovaných souborech.** `http-client.env.json` je bez secretů; token
  jen jako `{{$processEnv API_TOKEN}}` / `{{$dotenv API_TOKEN}}`. Skutečné hodnoty přes
  `http-client.private.env.json` (lokál) nebo pipeline secret / variable group (CI).
- **`.gitignore`** musí obsahovat `http-client.private.env.json` a `.env`. Pokud tam nejsou,
  doplň je a upozorni uživatele.
- **Žádná reálná citlivá data** v ukázkách ani fixture — jen placeholdery (`customer-12345`,
  `<API_TOKEN>`, `user@example.com`, `https://api.example.internal`).
- **Odchozí volání** na interní systémy Fullsys (FIS, BILLING 2.0, NEXT WMS) směřuj na jejich
  oficiální endpointy přes proměnné; do repa nikdy nedávej produkční URL s citlivým významem
  ani produkční tokeny.

## Kontrolní seznam

Před dokončením ověř:

- [ ] Proběhl krok 0 (existující `.http`, env soubory, runner, CI platforma) a výstup jim odpovídá?
- [ ] Jeden `.http` soubor na doménu/kontroler, requesty oddělené `###`?
- [ ] Base URL i token **jen přes proměnné** (`{{baseUrl}}`, `{{token}}`), nic hardcoded?
- [ ] `http-client.env.json` je commitovaný a **bez secretů**; secrety přes `$processEnv`/`$dotenv`?
- [ ] `http-client.private.env.json` je v `.gitignore` a obsahuje jen placeholdery?
- [ ] Requesty ověřované CI mají assert — buď deklarativní `??`, nebo `> {% client.test(...) %}`?
- [ ] CI spouští `httpyac send "<glob>" --all -e <env> --bail --junit` a publikuje JUnit?
- [ ] Publikace výsledků běží i při selhání testů (build přesto zčervená)?
- [ ] Vygenerována pipeline pro správnou platformu (Azure DevOps / GitHub / obojí)?

## Další soubory

- `SYNTAX.md` — podrobná syntaxe assert bloků httpyac (deklarativní `??` i skriptovací
  `> {% client.test(...) %}`, tabulky předmětů/operátorů/predikátů, kdy je assert povinný).
- `EXAMPLE.md` — kompletní ukázkové `.http` soubory a environment sada (`http-client.env.json`
  + `http-client.private.env.json`, scénáře 200/400/401, předání tokenu z loginu).
- `references/azure-devops.md` — YAML pipeline pro Azure DevOps (NodeTool, httpyac,
  PublishTestResults@2, variable groups).
- `references/github-actions.md` — workflow pro GitHub Actions (setup-node, httpyac,
  dorny/test-reporter, secrets, artifact).
