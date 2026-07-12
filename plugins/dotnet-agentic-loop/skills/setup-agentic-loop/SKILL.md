---
name: setup-agentic-loop
description: >-
  Použij, když chceš v .NET repozitáři zavést deterministickou agentickou
  verifikační smyčku — build a testy jako automatický pass/fail gate přes Claude
  Code hooks. Najde .sln/.csproj a testovací projekty, zapíše pravidla do CLAUDE.md
  a vygeneruje hooky verify-build.js (PostToolUse) a verify-tests.js (Stop).
  Nepoužívej pro ne-.NET projekty ani pro běžný build/test bez instalace smyčky.
user-invocable: true
---

# Nastavení agentické smyčky pro .NET projekt

Jsi na začátku úkolu, který se v libovolném .NET repozitáři vyvolá jako `/setup-agentic-loop`.
Cílem je, aby se v tomto repozitáři sám uzavřel cyklus **gather context → take action → verify work → repeat**
tak, že build a testy fungují jako deterministický pass/fail signál, ne jako věc, kterou musí kontrolovat člověk.

Postupuj přesně podle kroků níže. Nic nepřeskakuj, ale kde je to rozumné, zvol sensible default a pokračuj —
neptej se na věci, které si můžeš zjistit sám průzkumem repozitáře.

> [!NOTE]
> Hook skripty se v Kroku 3 nekopírují ručně z paměti — jsou přiložené jako šablony ve složce
> [`assets/`](./assets/) tohoto skillu. Ty jen dosadíš skutečné cesty a zapíšeš je do cílového repa.

---

## Krok 1 — Analýza projektu

Zjisti:

1. Najdi `*.sln` v kořeni repa. Pokud jich je víc, ověř jestli existuje `*.slnf` (solution filter) nebo vezmi
   ten sln, který zahrnuje nejvíc `*.csproj`. Pokud sln neexistuje, pracuj přímo s hlavním `*.csproj`.
2. Najdi testovací projekty — hledej v `*.csproj` reference na `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.v3`,
   `NUnit`, `MSTest.TestFramework`. Pojmenování obvykle `*.Tests.csproj`, `*.UnitTests.csproj`,
   `*.IntegrationTests.csproj`.
3. Zkontroluj `global.json` (pinned SDK verze) a `Directory.Build.props`/`Directory.Packages.props`
   (centralizovaná správa balíčků) — pokud existují, build příkaz na ně nemusí reagovat jinak, ale je
   dobré vědět, že tam jsou, kdyby build selhával z neočekávaného důvodu.
4. Ověř, jestli `.claude/settings.json` už existuje. Pokud ano, **nikdy ho nepřepisuj celý** — hooks jen
   přidej jako další položky do existujícího `hooks` objektu.

Z toho odvoď:

- `BUILD_TARGET` — cesta k `.sln` nebo hlavnímu `.csproj`
- `TEST_TARGET` — stejně, ale pro testy (může být stejný sln, pokud test projekty jsou v něm zahrnuté)
- `IS_MONOREPO` — true, pokud je v repu víc nezávislých modulů/test projektů (jako BILLING 2.0 / NEXT WMS
  ve stejném repu) — v tom případě zvaž volitelné vylepšení v Kroku 5.

---

## Krok 2 — Zápis do CLAUDE.md

Přidej (nebo vytvoř) do `CLAUDE.md` v kořeni repa sekci:

```markdown
## Agentická verifikační smyčka

Build: `dotnet build {{BUILD_TARGET}} --nologo`
Testy: `dotnet test {{TEST_TARGET}} --nologo`

Pravidla:
- Po každé netriviální změně v `.cs`/`.csproj` souboru spusť build. Kompilační chyby oprav ihned,
  neshromažďuj je na konec.
- Úkol NENÍ hotový, dokud build i testy neprojdou. Netvrď "hotovo", pokud jsi testy fakticky nespustil(a).
- Pokud test selže z důvodu mimo tvůj dosah (chybějící služba, špatné prostředí), řekni to explicitně
  místo opakovaných pokusů donekonečna.
- Automatizovaná kontrola běží i bez tebe přes hooks (viz `.claude/hooks/`) — bereš ji jako zdroj pravdy,
  ne jako formalitu.
```

Nahraď `{{BUILD_TARGET}}` a `{{TEST_TARGET}}` skutečnými cestami zjištěnými v Kroku 1.

> Idempotence: pokud sekce `## Agentická verifikační smyčka` v `CLAUDE.md` už existuje (opakované
> spuštění), jen ji aktualizuj — nepřidávej ji podruhé.

---

## Krok 3 — Hook skripty

Vytvoř v cílovém repu adresář `.claude/hooks/` a nakopíruj do něj dvě přiložené šablony. Do každé dosaď
skutečný `BUILD_TARGET`/`TEST_TARGET` z Kroku 1 — nahraď placeholder přímo v souboru (needeleguj to na
proměnné prostředí, ať je skript čitelný a přenositelný):

1. Přečti šablonu [`assets/verify-build.js`](./assets/verify-build.js), nahraď v ní `{{BUILD_TARGET}}`
   skutečnou cestou a výsledek zapiš do `.claude/hooks/verify-build.js` cílového repa.
2. Přečti šablonu [`assets/verify-tests.js`](./assets/verify-tests.js), nahraď v ní `{{TEST_TARGET}}`
   skutečnou cestou a výsledek zapiš do `.claude/hooks/verify-tests.js` cílového repa.

Jak hooky fungují (kontext pro případné úpravy, samotné soubory neměň nad rámec dosazení cesty):

- **`verify-build.js` (PostToolUse, matcher `Edit|Write`)** — po každé editaci `.cs`/`.csproj`/`.props`/`.targets`
  spustí `dotnet build`. Rychlá zpětná vazba. `exit 0` = žádná námitka, `exit 2` + stderr = feedback Claude
  (u PostToolUse akci neblokuje, ale Claude ho vidí a hned reaguje). Na jiné soubory nereaguje.
- **`verify-tests.js` (Stop)** — gate před dokončením tahu: `exit 2` **blokuje** ukončení, dokud `dotnet test`
  neprojde. Pojistka proti nekonečné smyčce je **primárně retry counter** (`.test-retry-count`, strop
  `MAX_RETRIES = 5`, reset na 0 po úspěchu i po dosažení stropu); `stop_hook_active` je jen **sekundární**
  pojistka — nikdy se na něj bezpodmínečně neexituje 0 (jinak by counter i MAX_RETRIES byly mrtvý kód).
- **Sdílený zámek `.dotnet-lock/`** — atomický `mkdir` (test-and-set) brání souběhu více `dotnet` procesů
  nad stejným řešením (zámky na `obj`/`bin` → falešné chyby). „Stale" zámek starší než 180 s se ukradne;
  Stop hook na zámek chvíli blokujícím způsobem čeká (`Atomics.wait`, max 60 s), protože test gate musí proběhnout.
- **Timeout ≠ chyba** — `ETIMEDOUT`/`SIGTERM` se hlásí jinak než skutečné selhání (aby build/testy nehlásily
  zavádějící „selhal" při pomalém cold NuGet restore).

Hooky si za běhu vytvářejí v `.claude/hooks/` pomocné soubory (retry counter, zámek, případně seznam
změněných souborů). Ty se nemají verzovat — přidej do `.gitignore` v kořeni repa (idempotentně, pokud
tam řádky ještě nejsou):

```gitignore
.claude/hooks/.test-retry-count
.claude/hooks/.dotnet-lock/
.claude/hooks/.changed-files
```

(`.changed-files` vzniká jen při monorepo optimalizaci z Kroku 5.)

---

## Krok 4 — settings.json

Přidej do `.claude/settings.json` cílového repa (vytvoř, pokud neexistuje; pokud existuje, **merguj** do
stávajícího `hooks` objektu, neztrácej cizí konfiguraci):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/verify-build.js\"" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/verify-tests.js\"" }
        ]
      }
    ]
  }
}
```

Ověř, že `node` je dostupný (`node --version`). Pokud ne, uprav shebang/spouštění na to, co je v prostředí
k dispozici, ale preferuj Node.js kvůli přenositelnosti mezi Windows/Linux.

> Idempotence: pokud `.claude/settings.json` už tyhle hooky z dřívějšího spuštění obsahuje, nepřidávej
> je znovu — před zápisem zkontroluj, jestli stejný `command` v daném eventu (`PostToolUse`/`Stop`) už
> zaregistrovaný není.

---

## Krok 5 — Volitelné vylepšení pro monorepo (BILLING 2.0 / NEXT WMS / FIS style)

Pokud `IS_MONOREPO = true`, zvaž rozšíření `verify-tests.js` tak, aby netestoval celé řešení, ale jen
testovací projekt relevantní k editovanému souboru:

Stop hook v payloadu **nemá** `tool_input` ani `file_path` (ty jsou dostupné jen u
`PreToolUse`/`PostToolUse`). Seznam změněných souborů si proto musíš předat sám jednou z těchto cest:

1. **Doporučeno:** `verify-build.js` (PostToolUse) při každé editaci připíše `input.tool_input.file_path`
   do dočasného souboru (např. `.claude/hooks/.changed-files`). `verify-tests.js` (Stop) ho na začátku
   přečte, odvodí z něj změněné moduly a soubor vyprázdní.
2. **Alternativa:** ve Stop hooku naparsuj transcript z `input.transcript_path` a vytáhni z něj poslední
   editace.

Z takto získané cesty pak projdi adresářový strom směrem nahoru, dokud nenajdeš sourozenecký
`*.Tests.csproj`:

- Pokud ho najdeš, spusť `dotnet test <ten projekt> --nologo` místo celého `TEST_TARGET`.
- Pokud nenajdeš (např. změna je ve sdílené knihovně), spadni zpět na celé řešení.

Stejná úvaha platí pro `verify-build.js`: v monorepu buildí celé řešení po **každé** editaci, což je
nejčastěji spouštěná (a tím i nejdražší) část smyčky. Když máš cestu ke změněnému souboru, můžeš i build
zúžit na dotčený projekt (`dotnet build <projekt>`) a na celé řešení spadnout zpět jen u změn ve sdílené
knihovně.

Tohle není nutné pro základní funkčnost — přidej to jen pokud je celé řešení pomalé na testování
(desítky sekund a víc) a chceš rychlejší zpětnou vazbu v smyčce.

---

## Krok 6 — Ověření a shrnutí

1. Spusť `dotnet build {{BUILD_TARGET}}` ručně, ať víš, že baseline je zelený, než hooky začnou vynucovat.
2. Řekni uživateli, aby si funkčnost ověřil příkazem `/hooks` (zobrazí zaregistrované hooky) nebo
   `claude --debug` (uvidí hook execution log).
3. Na závěr napiš krátké shrnutí: co bylo zjištěno (BUILD_TARGET, TEST_TARGET, je/není monorepo), jaké
   soubory vznikly, a upozorni, že schema hooků se mezi verzemi CLI mírně vyvíjí — pokud něco nesedí,
   ověřit proti aktuální dokumentaci (`code.claude.com/docs/en/hooks`).
