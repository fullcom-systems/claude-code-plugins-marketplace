# dotnet-testing

Meta-shrnutí: Skills-only plugin pro **testování libovolného .NET/C# projektu**. Obsahuje skilly
`dotnet-unit-tests` (unit testy) a `dotnet-http-tests` (HTTP/API testy přes `.http` soubory);
plugin je pojmenován obecně, aby unesl i další typy testů. Oba skilly sdílejí princip: na rozdíl
od projektově specifických konvencí (např. interní skill pro NextFIS) nejprve zjistí, co
repozitář už používá (framework, knihovny, existující `.http` soubory, CI platforma), a generují
tomu na míru. Pro nové unit-test projekty navrhuje `dotnet-unit-tests` licenčně nezávadný výchozí
stack (xUnit + NSubstitute + Shouldly); `dotnet-http-tests` staví na httpyac CLI kompatibilním
s VS Code REST Client i IntelliJ HTTP Client. Cílová skupina: vývojáři píšící nebo doplňující
testy v jakémkoli .NET repu.

## Obsah

- [Skills](#skills)
- [Bezpečnostní princip](#bezpečnostní-princip)
- [Instalace](#instalace)
- [Použití](#použití)

## Skills

| Skill | Účel |
|-------|------|
| `dotnet-unit-tests` | Zjistí konvence repozitáře (framework, mock/assert knihovny, umístění testů) a vygeneruje/doplní unit testy podle AAA patternu, s XML dokumentací a pojmenováním `{Metoda}_{Scénář}_{Očekávání}`. Detaily syntaxe v `SYNTAX.md`, referenční příklad v `EXAMPLE.md`. |
| `dotnet-http-tests` | Navrhne strukturu `.http` testů (jeden soubor na doménu/kontroler), environment soubory `http-client.env.json` / `http-client.private.env.json` s přepínáním local/staging/prod, assert bloky httpyac — deklarativní `??` i skriptovací `> {% client.test(...) %}` — a CI/CD pipeline (`httpyac send … --junit`). Formát kompatibilní s REST Client, httpyac i IntelliJ HTTP Client. Detaily syntaxe v `SYNTAX.md`, ukázkové soubory v `EXAMPLE.md`. Pipeline pro **Azure DevOps** i **GitHub Actions** — reference v `references/`. |

Plugin **nemá `.mcp.json`** — pracuje výhradně lokálně se soubory v repozitáři (čtení zdrojových
tříd, zápis testovacích a `.http` souborů, spuštění `dotnet test`). Samotné HTTP volání provádí
až vývojář nebo CI (httpyac), ne skill — žádná odchozí komunikace ze skillu není potřeba.

## Bezpečnostní princip

Skill nikdy negeneruje reálná citlivá data (PII, EIC/EAN/POD, čísla smluv, receptury, mzdy) do
testovacích fixture dat — pouze placeholdery/obecné hodnoty, konzistentně s bezpečnostními
pravidly Fullsys.

## Instalace

```
/plugin install dotnet-testing@fullsys-plugins
```

## Použití

Přirozeným jazykem, např.:

```
# unit testy (dotnet-unit-tests)
Napiš unit testy pro třídu DiscountCalculator.
Doplň testové scénáře pro metodu Calculate v OrderService.
Vytvoř unit testy pro tuhle třídu podle konvencí projektu.

# HTTP/API testy (dotnet-http-tests)
Vytvoř .http testy pro endpoint /api/customers, potřebuju environment local/staging/prod
  a spouštění v Azure DevOps.
Mám .http soubor na warehouse API, přidej k tomu CI v GitHub Actions.
Nastav environment switching pro REST Client testy, používáme Azure DevOps i GitHub.
```

Oba skilly nejdřív prozkoumají repozitář (existující testovací projekty a `.csproj` reference,
resp. existující `.http` soubory a CI platformu), teprve poté generují.

---

> Po úpravách: zvaliduj `./scripts/validate-marketplace.sh` a otevři PR — viz kořenový
> [CONTRIBUTING.md](../../CONTRIBUTING.md).
