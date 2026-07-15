# Příklad `.http` testů

Kompletní ukázkové soubory pro `.http` testy přes httpyac — environment sada i realistické
requesty s oběma syntaxemi assertů. Podrobnou syntaxi assert bloků najdeš v `SYNTAX.md`, CI/CD
pipeline v `references/`. Hodnoty jsou záměrně jen placeholdery — do repa nikdy nedávej reálné
tokeny, PII ani produkční hostnames s citlivým významem.

## Environment sada

Dva soubory vedle sebe. Commitovaný `http-client.env.json` **bez secretů**, secret jen jako
odkaz na proces env proměnnou; gitignored `http-client.private.env.json` s lokálními hodnotami.

```jsonc
// http-client.env.json  — COMMITOVANÝ, žádné secrety
{
  "local":   { "baseUrl": "https://localhost:5001", "token": "{{$processEnv API_TOKEN}}" },
  "staging": { "baseUrl": "https://staging.example.internal", "token": "{{$processEnv API_TOKEN}}" },
  "prod":    { "baseUrl": "https://api.example.internal", "token": "{{$processEnv API_TOKEN}}" }
}
```

`token` zde **není** secret — je to jen odkaz „vezmi hodnotu z proces env proměnné `API_TOKEN`".
Skutečná hodnota přijde lokálně z `http-client.private.env.json`, v CI z pipeline secret /
variable group injektované jako env proměnná `API_TOKEN` (viz reference dané platformy).

```jsonc
// http-client.private.env.json  — GITIGNORED, jen lokální dev, placeholdery ne reálné tokeny
{
  "local":   { "token": "<DEV_API_TOKEN>" },
  "staging": { "token": "<STAGING_API_TOKEN>" }
}
```

## Deklarativní asserce `??` — potvrzení skladových pohybů

Kompletní `.http` soubor s běžnými kontrolami stavu, těla a hlaviček (scénáře 200/400/401).
Syntaxe `??` viz `SYNTAX.md`.

```http
### Other movements - OK (všechna pole)
POST {{host}}/confirmation/other-movements
Authorization: Bearer {{apiKey}}
Content-Type: application/json

{
  "warehouse": "W1",
  "location_code_host_old": "LOC-A",
  "location_code_host_new": "LOC-B",
  "movement_type": "MOVE",
  "message_id": "msg-001",
  "item_number": "ITEM-001",
  "quantity": 10,
  "status_quality": "OK",
  "lot": "LOT-001",
  "expiration_date": "2026-12-31",
  "comment": "Testovací pohyb"
}

?? status == 200
?? body == true

### Other movements - OK (jen povinná pole)
POST {{host}}/confirmation/other-movements
Authorization: Bearer {{apiKey}}
Content-Type: application/json

{
  "warehouse": "W1",
  "item_number": "ITEM-001"
}

?? status == 200
?? body == true

### Other movements - chybí povinné pole warehouse (očekává 400)
POST {{host}}/confirmation/other-movements
Authorization: Bearer {{apiKey}}
Content-Type: application/json

{
  "item_number": "ITEM-001"
}

?? status == 400
?? body status_code == 400
?? body message == One or more errors occurred!

### Other movements - prázdné tělo requestu (očekává 400)
POST {{host}}/confirmation/other-movements
Authorization: Bearer {{apiKey}}
Content-Type: application/json

?? status == 400
?? body status_code == 400

### Other movements - chybí hlavička Authorization (očekává 401)
POST {{host}}/confirmation/other-movements
Content-Type: application/json

{
  "warehouse": "W1",
  "item_number": "ITEM-001"
}

?? status == 401
?? header www-authenticate == Bearer
```

## Skriptovací blok `> {% client.test %}` — seznam a login s předáním tokenu

Pro složitější kontroly (iterace nad polem) a předání hodnoty dalšímu requestu
(`client.global.set`). Vlastnosti dostupné v bloku viz `SYNTAX.md`.

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

### Login uloží token pro další requesty
POST {{baseUrl}}/api/auth/login
Content-Type: application/json

{ "user": "user@example.com", "password": "{{$processEnv TEST_PASSWORD}}" }

> {%
  client.test("status je 200", function () {
    client.assert(response.status === 200, "Očekáván status 200");
  });
  client.global.set("token", response.parsedBody.token);
%}
```

Uložený `token` (přes `client.global.set`) použijí následující requesty přes `{{token}}` —
typický vzor pro endpointy vyžadující autentizaci až po přihlášení.
