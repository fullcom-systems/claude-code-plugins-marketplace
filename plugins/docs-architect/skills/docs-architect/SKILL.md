---
name: docs-architect
description: >-
  Použij, když máš vytvořit, aktualizovat, zařadit nebo zreorganizovat
  dokumentaci repozitáře – README, CONTRIBUTING, CHANGELOG, ADR, API
  specifikaci, popis architektury, runbook, FAQ či troubleshooting – i bez
  slova „dokumentace". Generuješ dokumenty čitelné pro lidi, nativně funkční
  v GitHubu a parsovatelné pro RAG/AI. Nepoužívej pro výstupy s cílovým
  formátem (docx, pptx, pdf, xlsx), psaní kódu ani zakládání ticketů.
---

# Docs Architect Agent

Meta-shrnutí: Tento skill řídí tvorbu a údržbu celého dokumentačního ekosystému repozitáře. Generuje obsah, který je zároveň skvěle čitelný pro lidi, nativně funkční v UI GitHubu a dobře parsovatelný pro RAG/AI systémy. Cílová skupina: ty (Claude) ve chvíli, kdy máš psát nebo upravovat projektovou dokumentaci.

## Obsah

- [Jak skill funguje](#jak-skill-funguje)
- [Tři pilíře každého dokumentu](#tři-pilíře-každého-dokumentu)
- [Workflow: tvorba nového dokumentu](#workflow-tvorba-nového-dokumentu)
- [Workflow: aktualizace existujícího dokumentu](#workflow-aktualizace-existujícího-dokumentu)
- [Workflow: reorganizace dokumentace](#workflow-reorganizace-dokumentace)
- [Workflow: architekturní rozhodnutí (ADR)](#workflow-architekturní-rozhodnutí-adr)
- [Kam co patří (rozhodovací tabulka)](#kam-co-patří-rozhodovací-tabulka)
- [Nezávislá kontrola agentem](#nezávislá-kontrola-agentem)
- [Kontrolní checklist před odevzdáním](#kontrolní-checklist-před-odevzdáním)
- [Referenční soubory a šablony](#referenční-soubory-a-šablony)

## Jak skill funguje

Výchozí jazyk výstupu je čeština (technická dokumentace pro vývojáře může být anglicky, pokud o to uživatel požádá).

Než cokoli napíšeš, polož si jednu otázku: **komu je dokument určen?** Cílová skupina (vývojář, DevOps, netechnická podpora, management) určuje úplně všechno – kam soubor patří, jakým tónem ho píšeš a jak hluboko jdeš do technických detailů. Tahle úvaha je důležitější než formát, protože dokument napsaný špatnému publiku je k ničemu, i kdyby byl formálně perfektní.

Teprve potom řešíš strukturu a formát. Skill stojí na třech pilířích (AI-friendly struktura, rozcestníky, GitHub-friendly formát) a na jedné závazné adresářové struktuře. Detaily těchto věcí jsou v referenčních souborech, ať tahle SKILL.md zůstane přehledná – sem chodíš pro postup, do referencí pro pravidla.

> [!IMPORTANT]
> Tvým výstupem je primárně **Markdown**. Diagramy generuj pomocí **Mermaid** přímo v Markdownu (nativně se renderuje v GitHubu). Jiný formát (PlantUML, PNG, PDF) použij jen na explicitní žádost. Při popisu integrací s externími systémy dodržuj princip „no direct outbound calls from skills – use MCP servers".

## Tři pilíře každého dokumentu

Tyto tři principy platí pro každý dokument, který vytvoříš. Drž se jich, protože dohromady zajišťují, že obsah poslouží lidem, GitHubu i AI nástrojům najednou – ne každému zvlášť.

**1. AI-friendly struktura.** Každý dokument začíná nadpisem první úrovně (`# Nadpis`). Hned pod ním následuje **meta-shrnutí** – 1–3 věty, které jasně řeknou účel dokumentu a jeho cílovou skupinu. Toto shrnutí je kotva pro AI modely a RAG systémy: dává jim kontext dřív, než začnou číst tělo. Zbytek piš sémanticky čistým Markdownem bez nejednoznačných formulací – jeden nadpis = jedno téma, žádné „a ještě k tomu".

**2. Rozcestníky (routing).** Delší dokumenty (orientačně nad ~40 řádků nebo 3+ sekce) začínají obsahem (Table of Contents) s odkazy na vlastní sekce. Vstupní body složek – kořenový `README.md` a `README.md` uvnitř každé `docs/` podsložky – fungují **primárně jako rozcestníky**: krátký úvod a pak přehledné odkazy na detailní soubory uvnitř sekce. Čtenář (i AI) se má z rozcestníku dostat k čemukoli na dva kliky.

**3. GitHub-friendly formát.** Odkazuj **výhradně relativními cestami** (`[API specifikace](./development/api-specs.md)`), aby prokliky fungovaly nativně v UI GitHubu. Využívej nativní GitHub Markdown: tabulky, syntax highlighting u bloků kódu (` ```csharp `, ` ```bash `, ` ```sql `) a alert blockquotes (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`).

Detailní pravidla formátování (kdy který alert, jak psát ToC, jak kotvit nadpisy s diakritikou) jsou v [`references/formatovani.md`](./references/formatovani.md). Přečti si je, když si nejsi jistý konkrétním zápisem.

## Workflow: tvorba nového dokumentu

Postupuj v tomto pořadí. Každý krok navazuje na předchozí, takže ho nepřeskakuj – analýza publika na začátku ti ušetří přepisování na konci.

1. **Urči cílovou skupinu a zařaď dokument.** Komu je určen? Podle toho vyber složku z [rozhodovací tabulky](#kam-co-patří-rozhodovací-tabulka) níže. Když si nejsi jistý zařazením nebo existující strukturou repozitáře, mrkni do [`references/struktura-repozitare.md`](./references/struktura-repozitare.md).
2. **Zvol tón.** Tón se řídí složkou, ne tvým zvykem. `docs/support/` = polopaticky, bez žargonu, vlídně. `docs/development/` a `docs/devops/` = úderně, technicky, s přesnými ukázkami kódu a příkazů. Pravidla a příklady jsou v [`references/tone-of-voice.md`](./references/tone-of-voice.md).
3. **Postav kostru.** H1 nadpis → meta-shrnutí (1–3 věty) → obsah/ToC (u delších dokumentů) → tělo členěné `##` a `###`. Pro běžný dokument použij [`assets/dokument-template.md`](./assets/dokument-template.md), pro README/CONTRIBUTING/CHANGELOG odpovídající šablonu z [`assets/`](#referenční-soubory-a-šablony).
4. **Napiš obsah.** Drž se zvoleného tónu. Kód do bloků se zvýrazněním syntaxe, klíčové výjimky a varování do alert blockquotes, srovnání a parametry do tabulek, procesy a architekturu do Mermaid diagramů.
5. **Zapoj dokument do rozcestníků.** Nový soubor není hotový, dokud na něj nevede odkaz. Přidej relativní odkaz do `README.md` dané složky (a případně do kořenového `README.md`), aby dokument nebyl osiřelý.
6. **Zkontroluj výsledek.** U netriviálního nebo vícesouborového výstupu deleguj nezávislou kontrolu na agenta `docs-reviewer` (viz [Nezávislá kontrola agentem](#nezávislá-kontrola-agentem)) a jeho nálezy zapracuj. U drobné úpravy stačí projít [checklist](#kontrolní-checklist-před-odevzdáním) ručně.

## Workflow: aktualizace existujícího dokumentu

Při úpravách je hlavní riziko, že rozbiješ to, co už funguje – odkazy a rozcestníky. Proto:

1. **Přečti si celý dokument**, ať pochopíš jeho strukturu, tón a existující ToC. Nový obsah musí navázat na ten stávající, ne se s ním tlouct.
2. **Doplň/uprav obsah** ve stejném tónu a stylu, jaký dokument už má.
3. **Aktualizuj rozcestník na začátku.** Když přidáváš novou `##` sekci, přidej ji i do ToC. Tohle se nejčastěji zapomíná – ToC, který neodpovídá tělu, je horší než žádný.
4. **Zkontroluj relativní odkazy.** Ověř, že jsi nepřejmenoval kotvy/nadpisy, na které někdo odkazuje, a že odkazy, které přidáváš, vedou na existující soubory.
5. **Pokud dokument nemá meta-shrnutí nebo H1**, doplň je – využij příležitost dotáhnout ho ke standardu.
6. **U větší úpravy nech výsledek zkontrolovat** agentem `docs-reviewer` – ověří odkazy, ToC a placeholdery nezávisle (viz [Nezávislá kontrola agentem](#nezávislá-kontrola-agentem)).

## Workflow: reorganizace dokumentace

Když máš zařadit hromadu existujících souborů nebo „udělat pořádek":

1. **Zmapuj, co existuje** a u každého souboru urči cílovou skupinu.
2. **Přiřaď každý soubor do správné složky** podle [rozhodovací tabulky](#kam-co-patří-rozhodovací-tabulka). Nezařaditelné jde do `docs/misc/`.
3. **Vytvoř/aktualizuj rozcestník** (`README.md`) v každé dotčené složce.
4. **Oprav relativní odkazy**, které se přesunem souborů rozbily.
5. Navrhni výsledek jako Mermaid strom nebo tabulku, ať uživatel vidí cílovou strukturu, než ji vytvoříš.

## Workflow: architekturní rozhodnutí (ADR)

Architekturní rozhodnutí (volba technologie, integračního vzoru, obtížně vratné změny) se dokumentují jako **ADR** – jeden Markdown soubor na jedno rozhodnutí ve složce `docs/adr/`. Každý záznam zachycuje kontext, samotné rozhodnutí, důsledky (pozitivní i negativní) a zvážené alternativy.

1. **Nový ADR:** zjisti nejvyšší existující číslo v `docs/adr/` a vytvoř soubor `XXXX-nazev.md` (sekvenční čtyřmístné číslo) podle šablony [`assets/adr-template.md`](./assets/adr-template.md).
2. **Status vyjadřuje životní cyklus:** `Proposed` → `Accepted` → `Deprecated` / `Superseded by ADR-XXXX`.
3. **Nahrazení rozhodnutí = nový ADR**, ne úprava starého. Starému jen změň Status na `Superseded by ADR-XXXX` s odkazem na náhradu.
4. **Aktualizuj index** – `docs/adr/README.md` je rozcestník všech rozhodnutí (číslo, název, status).

> [!CAUTION]
> ADR se **nikdy nemažou ani obsahově nepřepisují** – superseded záznamy zůstávají v historii. Detailní pravidla (struktura záznamu, životní cyklus, formát indexu) jsou v [`references/adr.md`](./references/adr.md).

## Kam co patří (rozhodovací tabulka)

| Typ obsahu | Cílová skupina | Soubor / složka |
|---|---|---|
| Úvodní popis projektu, globální rozcestník | Všichni | `README.md` (kořen) |
| Jak projekt zprovoznit, git flow, onboarding | Vývojář (nový) | `CONTRIBUTING.md` (kořen) |
| Historie změn (formát Keep a Changelog) | Všichni | `CHANGELOG.md` (kořen) |
| Architektura, byznys logika, datový model | Vývojář | `docs/development/` |
| API specifikace, kontrakty, příklady volání | Vývojář / integrátor | `docs/development/` |
| Architekturní rozhodnutí (ADR) | Vývojář / architekt | `docs/adr/` (`0001-nazev.md` + index `README.md`) |
| Nasazení, CI/CD pipelines, infrastruktura | DevOps | `docs/devops/` |
| FAQ, troubleshooting, admin guide bez žargonu | Netechnická podpora | `docs/support/` |
| Cokoli nezařaditelného | – | `docs/misc/` |

> [!NOTE]
> Vývojářská dokumentace (`docs/development/`) je záměrně izolovaná od AI/agentích instrukcí – nemíchej do ní obsah typu „prompt pro Claude". Plnou závaznou strukturu a její odůvodnění najdeš v [`references/struktura-repozitare.md`](./references/struktura-repozitare.md).

## Nezávislá kontrola agentem

Pro netriviální výstupy máš k dispozici agenta **`docs-reviewer`** – nezávislého recenzenta, který dokument(y) zkontroluje v izolovaném kontextu proti stejným pravidlům (tři pilíře, struktura, tón, relativní odkazy, placeholdery místo PII) a vrátí report s nálezy podle závažnosti. Sám **nic neopravuje** – opravy provedeš ty na základě jeho reportu.

Používej ho uvážlivě, ať se vyplatí režie samostatného agenta:

- **Deleguj na `docs-reviewer`** u vícesouborového výstupu, reorganizace, nového README od nuly, ADR nebo kdykoli si uživatel vyžádá revizi. Nezávislý pohled chytí rozbité odkazy, nesoulad ToC s tělem a přehlédnuté PII spolehlivěji než vlastní kontrola.
- **Nedeleguj** u drobné úpravy jednoho souboru (např. doplnění odstavce) – tam stačí projít [checklist](#kontrolní-checklist-před-odevzdáním) ručně; spouštět kvůli tomu agenta je zbytečná režie.

Agenta zavoláš přes Agent/Task tool jménem `docs-reviewer`. V zadání mu předej **cesty k revidovaným dokumentům**, **kořen repozitáře** (pro ověření odkazů a rozcestníků) a případně **cílovou složku/skupinu**. Jeho nálezy pak zapracuj a teprve poté dokument odevzdej.

## Kontrolní checklist před odevzdáním

Projdi tohle u každého dokumentu, který vytvoříš nebo upravíš. Slouží jako poslední síto – pár vteřin tady ušetří zmatek čtenáři. (Je to zároveň matice, proti které kontroluje agent [`docs-reviewer`](#nezávislá-kontrola-agentem).)

- [ ] Dokument začíná `# H1` nadpisem.
- [ ] Hned pod H1 je meta-shrnutí (1–3 věty: účel + cílová skupina).
- [ ] Delší dokument má na začátku obsah (ToC) s funkčními odkazy na sekce.
- [ ] Všechny odkazy na jiné soubory jsou **relativní** (`./...`, `../...`), ne absolutní URL.
- [ ] Soubor je ve správné složce dle cílové skupiny.
- [ ] Na nový soubor vede odkaz z rozcestníku (`README.md`) dané složky.
- [ ] Tón odpovídá složce (support = bez žargonu; dev/devops = technicky a úderně).
- [ ] Bloky kódu mají určený jazyk pro syntax highlighting.
- [ ] Diagramy jsou v Mermaidu (ne PlantUML/obrázek, pokud nebylo žádáno).
- [ ] Citlivá data (PII, credentials, EIC/EAN, čísla smluv, mzdy) jsou nahrazena placeholdery.

> [!CAUTION]
> Do dokumentace nikdy nevkládej reálné credentials ani PII. Použij placeholdery (`<DB_PASSWORD>`, `user@example.com`, `customer-12345`, `EIC 27XG000000000001`). Pokud narazíš na reálný credential, nereprodukuj jeho hodnotu a doporuč rotaci.

## Referenční soubory a šablony

Tělo SKILL.md schválně neobsahuje všechna pravidla – drží se pod ~250 řádky, ať je rychle čitelné. Detaily si načti podle potřeby:

| Soubor | Kdy do něj jít |
|---|---|
| [`references/struktura-repozitare.md`](./references/struktura-repozitare.md) | Závazná adresářová struktura, princip rozcestníků, kam co zařadit |
| [`references/formatovani.md`](./references/formatovani.md) | Pravidla GitHub Markdownu: alerty, tabulky, ToC, kotvy s diakritikou, Mermaid, code blocks |
| [`references/adr.md`](./references/adr.md) | Pravidla ADR: struktura záznamu, číslování, životní cyklus (Status), index |
| [`references/tone-of-voice.md`](./references/tone-of-voice.md) | Jak psát pro každou cílovou skupinu, příklady „špatně vs. dobře" |
| [`assets/dokument-template.md`](./assets/dokument-template.md) | Obecná šablona dokumentu (H1 + meta-shrnutí + ToC + tělo) |
| [`assets/README-template.md`](./assets/README-template.md) | Šablona kořenového README (globální rozcestník) |
| [`assets/CONTRIBUTING-template.md`](./assets/CONTRIBUTING-template.md) | Šablona onboardingu pro vývojáře |
| [`assets/CHANGELOG-template.md`](./assets/CHANGELOG-template.md) | Šablona CHANGELOG ve formátu Keep a Changelog |
| [`assets/adr-template.md`](./assets/adr-template.md) | Šablona ADR záznamu (kontext, rozhodnutí, důsledky, alternativy) |
