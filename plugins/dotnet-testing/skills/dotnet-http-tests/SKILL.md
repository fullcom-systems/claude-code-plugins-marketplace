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
5. **Napiš / doplň `.http` requesty** s proměnnými a assert bloky.
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

Secret hodnoty se řeší přes odkaz na proces env proměnnou (`$processEnv`) / `$dotenv`, ne
zapsáním hodnoty:

```jsonc
// http-client.env.json  — COMMITOVANÝ, žádné secrety
{
  "local":   { "baseUrl": "https://localhost:5001", "token": "{{$processEnv API_TOKEN}}" },
  "staging": { "baseUrl": "https://staging.example.internal", "token": "{{$processEnv API_TOKEN}}" },
  "prod":    { "baseUrl": "https://api.example.internal", "token": "{{$processEnv API_TOKEN}}" }
}
```

`token` zde **není** secret — je to jen odkaz „vezmi hodnotu z proces env proměnné `API_TOKEN`".
Skutečná hodnota přijde:

- **lokálně** z `http-client.private.env.json` (gitignored, přepíše hodnotu z commitovaného souboru),
- **v CI** z pipeline secret / variable group injektované jako env proměnná `API_TOKEN`
  (viz reference dané platformy).

```jsonc
// http-client.private.env.json  — GITIGNORED, jen lokální dev, placeholdery ne reálné tokeny
{
  "local":   { "token": "<DEV_API_TOKEN>" },
  "staging": { "token": "<STAGING_API_TOKEN>" }
}
```

> Do commitovaných souborů nikdy nepiš reálné tokeny, hesla, PII ani interní hostnames s
> citlivým významem — jen placeholdery (`<API_TOKEN>`, `https://api.example.internal`).

## Ukázkový `.http` soubor

Base URL a token **vždy přes proměnné** (`{{baseUrl}}`, `{{token}}`), nikdy hardcoded. Requesty
oddělené `###`. Assert blok httpyac syntaxí `> {% client.test(...) %}`:

```http
### Seznam zákazníků vrátí 200 a neprázdné pole
GET {{baseUrl}}/api/customers
Authorization: Bearer {{token}}
Accept: application/json

> {%
  client.test("status je 200", function () {
    client.assert(response.status === 200, "Očekáván status 200, vráceno " + response.status);
  });
  client.test("odpověď je neprázdné pole", function () {
    client.assert(Array.isArray(response.parsedBody) && response.parsedBody.length > 0,
      "Očekáváno neprázdné pole zákazníků");
  });
%}

### Detail zákazníka vrátí 200 a správné ID
GET {{baseUrl}}/api/customers/customer-12345
Authorization: Bearer {{token}}
Accept: application/json

> {%
  client.test("status je 200", function () {
    client.assert(response.status === 200, "Očekáván status 200");
  });
  client.test("vrácené ID odpovídá požadovanému", function () {
    client.assert(response.parsedBody.id === "customer-12345", "Nesouhlasí ID zákazníka");
  });
%}
```

### Assert bloky — kdy jsou povinné

- **Povinné** pro každý request, který **ověřuje CI** — bez `client.test(...)` httpyac request
  jen odešle a nemá co reportovat (v JUnit se neobjeví jako test).
- **Nepovinné** pro čistě manuální / ad-hoc requesty, které slouží k ručnímu prozkoušení a CI
  je nespouští.

Užitečné vlastnosti v assert bloku: `response.status`, `response.headers`, `response.body`
(text), `response.parsedBody` (JSON), `client.assert(cond, message)`, `client.global.set(k, v)`
(předání hodnoty dalšímu requestu, např. tokenu z login požadavku).

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
- [ ] Requesty ověřované CI mají assert blok `> {% client.test(...) %}`?
- [ ] CI spouští `httpyac send "<glob>" --all -e <env> --bail --junit` a publikuje JUnit?
- [ ] Publikace výsledků běží i při selhání testů (build přesto zčervená)?
- [ ] Vygenerována pipeline pro správnou platformu (Azure DevOps / GitHub / obojí)?

## Další soubory

- `references/azure-devops.md` — YAML pipeline pro Azure DevOps (NodeTool, httpyac,
  PublishTestResults@2, variable groups).
- `references/github-actions.md` — workflow pro GitHub Actions (setup-node, httpyac,
  dorny/test-reporter, secrets, artifact).
