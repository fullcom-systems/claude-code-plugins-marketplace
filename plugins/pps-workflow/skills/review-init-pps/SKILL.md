---
name: review-init-pps
description: >-
  Použij, když chce uživatel pro mikroslužbu PPS G2 připravit nebo aktualizovat REVIEW.md, tedy
  kontrakt, podle kterého skill review-pps dělá code review — „připrav REVIEW.md pro machinery",
  „navrhni pravidla review pro tohle repo", „repo nemá REVIEW.md", „/review-init-pps planning".
  Zinventarizuješ autority repa, kandidáty pravidel ověříš v kódu, návrh vyzkoušíš na skutečném PR
  a zapíšeš ho mimo repo. Nepoužívej pro samotné review (review-pps) ani pro psaní AGENTS.md
  či CLAUDE.md.
argument-hint: "[repo] [--vystup <cesta>] [--bez-kalibrace]"
allowed-tools: Read, Grep, Glob, Write, Bash(pwsh -NoProfile -File *), Bash(git -C * grep *), Bash(git -C * log *), Bash(git -C * show *), Bash(git -C * rev-parse *), Bash(git -C * ls-files *), Bash(git -C * worktree *), Bash(git -C * status *), Bash(rm -rf *)
---

# Návrh REVIEW.md — mikroslužby PPS G2

Cíl: kontrakt, podle kterého `review-pps` posuzuje změny v daném repu. Návrh musí být **pravdivý
vůči kódu**. Každé pravidlo v něm je doložené a nic z něj neopisuje autority. Kontrakt, který tvrdí
něco, co kód nedělá, vyrobí falešné nálezy u každého review.

Skripty leží ve skillu `review-pps` (sourozenecká složka tohoto skillu): `../review-pps/scripts/`
vůči base directory, kterou ti harness oznámil při načtení. Šablona: [`references/sablona-REVIEW.md`](references/sablona-REVIEW.md).

---

## Argumenty

| Argument | Výchozí | Význam |
|---|---|---|
| repo | aktuální git repo | Složka mikroslužby nebo cesta k ní. Mimo git repo se zeptej. |
| `--vystup <cesta>` | pracovní adresář (níž) | Kam zapsat návrh `REVIEW.md`. Nástroj `Write` složku založí sám. |
| `--bez-kalibrace` | vypnuto | Přeskočit zkušební review na skutečném PR (krok 5). |

Existuje-li v repu `REVIEW.md`, jde o **aktualizaci**: vycházej z něj, měň jen to, co inventura
a ověření vyvrátí nebo doplní, a změny na konci vyjmenuj.

**Pracovní adresář** `<prac>`: máš-li scratchpad, `<scratchpad>/review-init-<repo>`, jinak
`<temp>/pps-review-init-<repo>`. Patří do něj inventura, výstupy `review-diff.ps1` (vždy s `-OutDir`) i kalibrační
worktree. Na konci ho smaž, kromě návrhu, pokud `--vystup` nebylo zadané.

---

## Pravidla kontraktu (v1)

- **Frontmatter:** `review-kontrakt: 1` (povinné), `base:` (výchozí base větev, v PPS `dev-sprint`),
  `vynechat:` (jen soubory **navíc** k výchozím: lock soubory, `Migrations/*.Designer.cs`, `*ModelSnapshot.cs`),
  `vynechat-pravidla:` (globy pravidel z `.claude/rules` / `.ai-rulez/rules`, která se kódu netýkají, např.
  workflow nebo OpenSpec bridge s `apply: always`).
- **Povinné sekce:** `## Autority`, `## Závažnost`, `## Na co se zaměřit`, `## Neřeš`.
  Volitelné: `## Co číst podle změněné cesty`, `## Pravidlo důkazu` (jen zpřísnění), `## Co v kódu ještě není`.
- **Škála závažnosti je pevná** (🔴 critical, 🟠 high, 🟡 medium, 🟢 low, ℹ️ info). Repo dodává jen příklady.
  Kategorie najdeš v `../review-pps/references/obecna-pravidla.md`.
- **Mapa cest** (`## Co číst podle změněné cesty`): tabulka `Zdroj | Platí pro | Poznámka`, zdroj jako odkaz,
  globy v backticks. Jen pro zdroje **bez** `paths:` ve frontmatteru: znalostní skilly a specifikace chování
  (`openspec/specs/<capability>/spec.md`). Glob je permisivní: `*` zasáhne i `/`, `**/` i nula složek.
- **Neodkazuj na generované cesty** (`.agents/`, cokoli gitignorovaného). U kolegy bez generování by odkaz vedl nikam.
- **Limit 200 řádků, cíl do 150.** Pravidla se neopisují, jen se na ně odkazuje.
- Co platí ve všech repech, drží PPS baseline (`../review-pps/references/pps-baseline.md`) – neopakuj ho,
  jen ho v `REVIEW.md` přizpůsob mechanismu repa (např. jak se tu publikuje přes outbox).
- Odkazy relativně ke kořeni repa (návrh bude ležet v kořeni). Žádná data zákazníka ani credentials.

---

## Postup

### 1. Inventura

```bash
pwsh -NoProfile -File "<base dir>/../review-pps/scripts/review-inventory.ps1" -RepoPath <repo> -OutDir <prac>/inventura
```

Výstup `REPO=`, `HEAD=`, `BASE=`, `CONTRACT=`, `INVENTORY=`, `WARN=`, při chybě `ERROR=` (pak skonči). Přečti
`inventory.md` celý. Obsahuje:
- autority s počtem řádků a stavem v gitu, pravidla a skilly,
- rozbité odkazy (kandidáti na rozpor) a odkazy do generovaných cest,
- stack: frameworky, balíčky, `EnforceCodeStyleInBuild` a vypnuté diagnostiky,
- pipeline a historii posledních commitů base větve, včetně souborů měněných skoro v každém PR.

Hlásí-li `WARN=`, že centrální obsah ai-rulez není vygenerovaný, řekni to uživateli a nabídni `npx ai-rulez generate`.
Sám ho nespouštěj, mění pracovní strom repa. Bez generování znáš jen názvy:
- skillů z `.ai-rulez/registry.md`,
- pravidel z bloku ai-rulez v `.gitignore` (inventura je vypíše).

Na jejich obsah se nespoléhej. Ta, která by mohla review ovlivnit, dej do otevřených otázek.

### 2. Přečti autority — v jedné zprávě

Jen soubory **v gitu** (netrackované zmiň, ale nestav na nich). Podle druhu:

| Druh | Příklady | Jak číst |
|---|---|---|
| Autority s pravidly | `CLAUDE.md`, `AGENTS.md` / `.ai-rulez/context/AGENTS.md`, `.ai-rulez/project-map.md`, pravidla s frontmatterem, znalostní skilly (`user-invocable: false`, vzory a konvence) | celé |
| Specifikace chování | `openspec/specs/*/spec.md`, ADR | jen přehled (nadpisy, čeho se týkají) → kandidáti do mapy cest |
| Konfigurace | `.editorconfig`, `Directory.Build.props`, `global.json`, pipeline | necti celé; inventura z nich vytáhla, co potřebuješ, zbytek hledej (`Grep`) |

Na projektové a git workflow skilly (commit, PR, task) nesahej, review se netýkají.

### 3. Sestav kandidáty pravidel

Kandidát = tvrzení, které má review hlídat, **a build, test, `.editorconfig` ani Sonar ho nechytí**. Ke každému:
oblast, závažnost podle škály, zdroj (autorita a sekce, nebo vzor v kódu).

Kde hledat. Oblasti platí všude, příklady mechanismů jsou z pilotů. Který mechanismus repo používá, poznáš
podle stacku v inventuře:

| Oblast | Starší služby (EF/Mongo, MediatR, kontrolery) – `planning`, `technology` | Služby na `Skoda.Pps.SharedPackages` (Mongo, `ApplicationCommand`) – `machinery`, `manufactory` |
|---|---|---|
| Vstupní body a autorizace | bázový kontroler s `[Authorize]` / `ApiControllerAuthorizeBase` | `AuthorizedApiController` + `[AuthByLevel]` na akci |
| Zápis, transakce, publikace (PPS baseline) | `IUnitOfWork` session + `ProduceEventToOutbox`, `BeginTransactionAsync` + `Produce(…, dbTransaction)` | `ApplicationCommand` + `BusinessTransactionBehaviour`, `IEventProducer.ProduceAsync` |
| Event processory, consumery | výjimka: propagace (`throw;`) vs. spolknutí, log s identifikátorem | `AbstractEventProcessor<T>`, validátor a mapping profil u consumeru |
| Čtení vs. zápis, validace, chyby | query vs. repository, FluentValidation, error kódy + `[SwaggerResponse]` | `Queries/Services` vs. repository, `IValidator<…Request>` |
| Persistence | interceptory, soft delete, EF migrace ve stejném PR | Mongo migrace (`IMigration`) a indexy |
| Doména | – | agregát bez veřejného konstruktoru a setteru, žádná persistence v Domain |
| Specifikace | – | změna chování upraví `openspec/specs/<capability>/spec.md` |
| Testy | frameworky z inventury, konvence ze skillu nebo README testů | bázové třídy testů (`CommandHandlerTest<T>`, `AggregateTest<T>`) |

**Šum:** soubory z inventury měněné v ≥ 60 % commitů (typicky `<Version>` v csproj) → `## Neřeš`.

**Styl:** do *Neřeš* patří jen to, co build nebo Sonar **opravdu** hlídá. Bez `EnforceCodeStyleInBuild` (inventura)
pravidla stylu z `.editorconfig` build nevynucuje. Pak napiš „formátování podle `.editorconfig` – nález jen tam, kde
mění chování“, ne „vynucuje build“.

### 4. Ověř každého kandidáta v kódu

Pravidlo, které neověříš, do `REVIEW.md` **nepiš**. Patří do seznamu otevřených otázek pro uživatele.

- **Konvenci doložíš počtem** pomocným skriptem (bez shellových rour, ty `allowed-tools` nepovolují):
  ```bash
  pwsh -NoProfile -File "<base dir>/../review-pps/scripts/review-count.ps1" -RepoPath <repo> \
      -Files 'src/**/*.cs' -Select ': AbstractEventProcessor<[\s\S]*catch' -Expect 'throw;'
  ```
  Vrací `POPULATION=`, `CONFORM=` a `MISS=` (odchylky). Regulární výrazy jsou .NET a `-Absent` počítá soubory, kde
  vzor **není** (např. `AllowAnonymous`). Výsledek zapiš jako „84 z 84 processorů s `catch` výjimku znovu vyhodí“.
  Kde je odchylek hodně, konvence neplatí. Napiš to a pravidlo zmírni nebo vypusť.
- **Mechanismus doložíš čtením implementace,** ne názvu (interceptor, bázová třída, behaviour). Popis v autoritě
  může být nepřesný. Leží-li mechanismus ve sdíleném balíčku (`shared-packages`, `fullsys-brokers`, `Infrastructure`
  v sourozeneckých repech), čti zdroj **té verze, kterou repo referencuje** (`<PackageReference Version>` → tag nebo commit
  v repu balíčku). HEAD balíčku může umět víc než verze, kterou služba používá.
- **Rozpor autorita × kód** (zastaralá verze SDK, přejmenovaná složka, jinak fungující mechanismus, rozbitý odkaz
  z inventury) do `REVIEW.md` nepiš. `REVIEW.md` se řídí kódem a rozpor vypiš uživateli (krok 7).
- Sdílená pravidla mimo repo (symlinky, centrální setup), která v checkoutu nejsou, review číst nemůže. Co z nich
  platí, musí být v autoritě repa nebo v `REVIEW.md`.

### 5. Zapiš návrh a vyzkoušej ho na skutečném PR

1. Napiš návrh podle šablony do `--vystup` (výchozí `<prac>`) jako `REVIEW.md`. Komentáře šablony smaž.
   Položka v `## Na co se zaměřit` má tvar **co hlídat – závažnost, důkaz nebo odkaz na autoritu › sekci, výjimky**.
   Nepřepisuj pravidlo autority celé, jen ho kalibruj:
   - ✅ „Processor výjimku propaguje (`throw;`) – 🟠, 84/84 processorů, `CLAUDE.md` › Přehled projektu“
   - ❌ odstavec, který převypráví sekci `AGENTS.md` vlastními slovy
2. Ověř formu:
   ```bash
   pwsh -NoProfile -File "<base dir>/../review-pps/scripts/review-diff.ps1" -RepoPath <repo> -Base HEAD -ContractPath <návrh> -OutDir <prac>/kontrola
   ```
   Skript kontroluje odkazy, délku, verzi, povinné sekce a to, že každý glob z mapy sedí aspoň na jeden soubor v gitu.
   Kromě `WARN=` o čtení kontraktu odjinud a o prázdném diffu nesmí přijít žádné varování.
3. **Kalibrace** (pokud ji uživatel nevypnul): z tabulky commitů v inventuře vyber jeden PR se 3–12 soubory **kódu**
   (sloupec *Z toho kód*), nejlépe takový, který se dotýká oblastí z kroku 3. Číslo PR je v popisu commitu. Pak:
   ```bash
   git -C <repo> worktree add --detach <prac>/worktree <commit>
   pwsh -NoProfile -File "<base dir>/../review-pps/scripts/review-diff.ps1" -RepoPath <prac>/worktree -Base <commit>^ -ContractPath <návrh> -OutDir <prac>/kalibrace
   ```
   Projdi ho podle `review-pps` (kroky 2–4). Sleduj tři věci:
   - nálezy, které jsou jen šum (pravidlo je moc přísné, nebo patří do *Neřeš*),
   - pravidla, u kterých nešlo vyplnit sloupec *Pravidlo*,
   - konvence jiného repa, které se sem nepřenášejí.

   Podle toho návrh uprav. Worktree pak odstraň (`git -C <repo> worktree remove --force <cesta>`, předtím
   `git -C <cesta> status --short`).

### 6. Hlídej délku a jazyk

Do 150 řádků. Česky, identifikátory jako v kódu. Žádné domněnky v textu: co není ověřené, v návrhu není.

### 7. Výstup uživateli

```markdown
**Návrh REVIEW.md pro `<repo>`** (HEAD `<hash>`) → `<cesta k návrhu>` · <N> řádků · kalibrace: PR <číslo> | vypnutá

| Pravidlo | Závažnost | Důkaz |
|---|---|---|
| Processor výjimku propaguje | 🟠 | 84/84 processorů s `catch` volá `throw;` |

**Bezpečnostní nálezy** (hodnota neuvedena): <typ> v `<soubor:řádek>` · doporučení: rotace a nahlášení
                                                   ← jen když nějaký je

**Rozpory autorit s kódem** (do REVIEW.md nepsané, opravit v autoritě):
- `CLAUDE.md:<řádek>` tvrdí X, kód dělá Y (`soubor:řádek`)

**Otevřené otázky** (neověřené, v návrhu nejsou):
- …

**Kalibrace:** <co se na PR ukázalo a co se v návrhu změnilo>
```

Tabulka obsahuje **všechna** pravidla z `## Na co se zaměřit`, každé na jeden řádek. Je to doklad, že žádné není
neověřené.

Na konci jednou větou: návrh leží mimo repo. Do repa ho zapíšeš jen na výslovný pokyn, nejlépe přes PR,
aby kritéria viděl celý tým.

---

## Hranice

- **Do repa nic nezapisuj**, ani `REVIEW.md`, ani opravu autorit. Na výslovný pokyn smíš zapsat jen `REVIEW.md`
  do kořene. Necommituj a nepushuj.
- `npx ai-rulez generate` ani jiné generátory nespouštěj, mění pracovní strom repa.
- Po sobě ukliď: kalibrační worktree (`git -C <repo> worktree remove --force <prac>/worktree`, předtím
  `git -C <prac>/worktree status --short`) a pak celý `<prac>` (`rm -rf`), kromě návrhu, pokud v něm leží.
  `rm -rf` používej jen na `<prac>`. Jiné worktrees repa (uživatelovy) nech být.
- Narazíš-li v repu na credentials, hodnotu nereprodukuj: uveď typ a místo a doporuč rotaci.
