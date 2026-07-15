# Assert bloky httpyac — syntaxe

Podrobná syntaxe pro ověřování odpovědí v `.http` testech přes **httpyac**. Použij jako referenci
poté, co v kroku 0 (`SKILL.md`) zjistíš, jaké konvence repozitář používá. Kompletní ukázkové
`.http` soubory najdeš v `EXAMPLE.md`.

Base URL a token zapisuj **vždy přes proměnné** (názvy dle konvence repa — např.
`{{baseUrl}}`/`{{token}}` nebo `{{host}}`/`{{apiKey}}`), nikdy hardcoded. Requesty odděluj `###`.

## Dvě syntaxe (obě akceptované)

httpyac nabízí dvě syntaxe ověření — skill akceptuje **obě** a lze je i **míchat** v jednom
souboru. Vyber podle složitosti kontroly:

| Syntaxe | Kdy použít |
|---------|-----------|
| **Deklarativní asserce `??`** | **preferováno** pro běžné kontroly stavu, těla a hlaviček — jeden řádek na podmínku, stručné a čitelné |
| **Skriptovací blok `> {% client.test(...) %}`** | složitější logika: podmínky, cykly, výpočty nebo předání hodnoty dalšímu requestu (`client.global.set`) |

Obě běží v httpyac lokálně i v CI a obě se objeví v JUnit reportu. Prosté VS Code REST Client
(`humao.rest-client`) asserce nespouští — to nevadí, ověřování dělá httpyac; REST Client slouží
k ručnímu odeslání requestu.

## Deklarativní asserce `??`

Řádky `??` následují **za tělem requestu**. Tvar: `?? <předmět> <operátor> <hodnota>`.

| Předmět | Příklad | Význam |
|---------|---------|--------|
| `status` | `?? status == 200` | HTTP status kód |
| `body` (celé tělo) | `?? body == true` | celé tělo odpovědi se rovná hodnotě |
| `body <cesta>` | `?? body status_code == 400` | vlastnost z JSON těla (JSONPath; `$.` je volitelný) |
| `header <název>` | `?? header www-authenticate == Bearer` | hodnota hlavičky odpovědi |
| `duration` | `?? duration < 5000` | doba odezvy v ms |

Operátory: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains`, `startsWith`, `endsWith`,
`matches` (regex). Predikáty bez hodnoty: `isNumber`, `isString`, `isBoolean`, `isArray`,
`exists`. Řetězcová hodnota se píše **bez uvozovek** (`?? body message == One or more errors occurred!`).

Krátká ukázka:

```http
### Other movements - OK
POST {{host}}/confirmation/other-movements
Authorization: Bearer {{apiKey}}
Content-Type: application/json

{ "warehouse": "W1", "item_number": "ITEM-001" }

?? status == 200
?? body == true
```

> Kompletní sada scénářů (200/400/401 včetně chybějící hlavičky a prázdného těla) je v `EXAMPLE.md`.

## Skriptovací blok `> {% client.test(...) %}`

Pro kontroly, které deklarativní `??` neunese (výpočet, iterace nad polem, uložení hodnoty pro
další request). Blok následuje za tělem requestu a obsahuje jeden nebo více `client.test(...)`.

Krátká ukázka:

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
```

Užitečné vlastnosti ve skriptovacím bloku:

| Vlastnost / metoda | Význam |
|--------------------|--------|
| `response.status` | HTTP status kód |
| `response.headers` | hlavičky odpovědi |
| `response.body` | tělo odpovědi jako text |
| `response.parsedBody` | tělo odpovědi jako JSON |
| `client.assert(cond, message)` | ověření podmínky s chybovou zprávou |
| `client.global.set(k, v)` | předání hodnoty dalšímu requestu (např. tokenu z login požadavku) |

> Kompletní příklad včetně předání tokenu z loginu do dalších requestů je v `EXAMPLE.md`.

## Assert bloky — kdy jsou povinné

- **Povinné** pro každý request, který **ověřuje CI** — bez asserce (`??` ani `client.test(...)`)
  httpyac request jen odešle a nemá co reportovat (v JUnit se neobjeví jako test).
- **Nepovinné** pro čistě manuální / ad-hoc requesty, které slouží k ručnímu prozkoušení a CI
  je nespouští.
