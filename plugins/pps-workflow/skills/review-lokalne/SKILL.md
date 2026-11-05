---
name: review-lokalne
description: >-
  Použij, když chce uživatel před založením PR projít změnu v mikroslužbě PPS G2 code review
  na svém stroji — „udělej mi review", „projdi diff proti dev-sprint", „/review-lokalne planning".
  Připravíš anotovaný diff, najdeš kontrakt repa (REVIEW.md) a pravidla podle změněných cest
  a vypíšeš nálezy do terminálu; nic nepublikuješ. Nepoužívej pro vysvětlení cizího PR,
  vypořádání připomínek z PR (pr-fix-pps) ani obecný lov chyb bez pravidel repa (/code-review).
argument-hint: "[repo] [base větev] [--rozpracovane]"
allowed-tools: Read, Grep, Glob, Bash(pwsh -NoProfile -File *), Bash(git -C * grep *), Bash(git -C * log *), Bash(git -C * show *), Bash(git -C * rev-parse *), Bash(git -C * status *), Bash(git -C * branch *)
---

# Lokální code review — mikroslužby PPS G2

Cíl: projít změnu **podle pravidel daného repa**, na stroji vývojáře a dřív, než vznikne PR.
Skill drží jen postup. Co se v repu hlídá, drží repo samo (`REVIEW.md` a jeho autority). Pravidla
proto **neopisuj z paměti ani odsud**, čti je ze zdrojů, které najde skript.

Specifikace kontraktu (verze 1): [`references/kontrakt-v1.md`](references/kontrakt-v1.md). Při review ji
nečti, je určená autorům `REVIEW.md` (návrh připraví skill `review-init`).

---

## Argumenty

| Argument | Výchozí | Význam |
|---|---|---|
| repo | aktuální git repo | Složka mikroslužby (`planning`) nebo cesta k ní. Ze složky, která není git repo (pracovní prostor s více repy), je povinný. |
| base | `base` z `REVIEW.md`, jinak `dev-sprint` | Proti čemu porovnávat. Diff je three-dot (proti společnému předku), jako u PR. Holé jméno větve skript bere z `origin/`. |
| `--rozpracovane` | vypnuto | Posoudit i necommitované změny (`-IncludeWorkingTree`). |

- První argument, který je existující složkou, je repo. Další argument bez `--` je base. Zbytek ignoruj.
- `--rozpracovane` přidej i bez argumentu, když je ze zadání zřejmé, že jde o rozdělanou práci
  („projdi mi, co mám rozdělané", „ještě to nemám commitnuté").
- Bez repa a mimo git repo se zeptej, kterou mikroslužbu posoudit. Nehádej.
- Je-li aktuální větev repa sama base větví (`dev-sprint`) a uživatel base nezadal, zeptej se, proti
  čemu porovnávat. Diff proti sobě samému je prázdný.

---

## Postup

### 1. Připrav vstup

```bash
pwsh -NoProfile -File "<adresář tohoto skillu>/scripts/review-diff.ps1" -RepoPath <repo> [-Base <base>] [-IncludeWorkingTree]
```

`<adresář tohoto skillu>` je base directory, kterou ti harness oznámil při načtení skillu. Skript
nekopíruj do repa.

Skript vypíše řádky `KLÍČ=hodnota`:

| Klíč | Co s ním |
|---|---|
| `ERROR=` | Skript selhal. Řekni proč a skonči. |
| `CONTRACT=` | Cesta k `REVIEW.md`, nebo `none` (pak platí krok 2, fallback). |
| `CONTRACT_VERSION=` | Verze kontraktu. |
| `BASE=` | Base, proti které se skutečně porovnávalo. Uveď ji v hlavičce výstupu. |
| `DIFF_DIR=`, `INDEX=` | Patche (`001.patch`, …) a `index.tsv` (patch, cesta, `+přidáno/-odebráno`). |
| `RULES=` | `review-rules.tsv`: `zdroj<TAB>důvod`, důvod je `paths:<glob>`, `vždy`, `mapa:<glob>` nebo `popis`. |
| `AUTHORITIES=` | Autority ze sekce `## Autority` v `REVIEW.md` (bez kontraktu fallback). Jejich počet patří do hlavičky. |
| `SKIPPED=` | Počet souborů vynechaných podle `vynechat` (seznam v `skipped.txt` vedle `pr.diff`). |
| `CRITERIA_CHANGED=` | Změna mění kritéria review (`REVIEW.md`, pravidla, `CLAUDE.md`…). Viz krok 3. |
| `WARN=` | Varování. **Každé přepiš do výstupu**, i když se ve výpisu ztratí. |

⚠️ **Vstup si nepřipravuj ručně a diff nečti přes `git diff`.** Jen anotace řádků
(`<starý> <nový>| `) drží odkazy v nálezech přesné. Skript navíc vybírá pravidla podle změněných cest.
Ta se v režimu review sama nenačtou, protože je spouští čtení souboru, ne patch.

Není-li `pwsh` k dispozici, nepokoušej se skript nahradit. Řekni, že je potřeba PowerShell 7
(`brew install powershell` na macOS, `winget install Microsoft.PowerShell` na Windows), a skonči.

Hlásí-li `WARN=`, že proti base není žádná změna, řekni to a skonči.

### 2. Přečti kritéria — v jedné zprávě

Všechno naráz, jedním blokem volání `Read`:

1. [`references/obecna-pravidla.md`](references/obecna-pravidla.md): škála závažnosti, pravidlo důkazu, hranice.
2. [`references/pps-baseline.md`](references/pps-baseline.md): společný základ PPS.
3. `REVIEW.md` (je-li `CONTRACT` jiný než `none`).
4. Každý zdroj z `RULES` s důvodem `paths:`, `vždy` nebo `mapa:`. Zdroj s důvodem `popis` čti, jen když
   jeho `description` ve frontmatteru odpovídá změněným oblastem.
5. Autority vyjmenované v sekci `## Autority` v `REVIEW.md`.
6. `index.tsv`.

**Fallback, když `CONTRACT=none`:** místo bodů 3 a 5 čti, co z toho v repu existuje: `CLAUDE.md`,
`.ai-rulez/context/AGENTS.md`, `AGENTS.md` a `.github/copilot-instructions.md`. Na **první řádek výstupu**
napiš: *„Repo nemá REVIEW.md – review je obecné, jen podle autorit a PPS baseline.“* Na konci výstupu nabídni
`/review-init <repo>`, který návrh připraví.

### 3. Posuď změnu

- Přečti patche naráz, jedním blokem volání (u velkého diffu po částech podle `index.tsv`). Kontext kolem změny čti
  ze **zdrojových souborů v repu** (`Read`, `git -C <repo> grep`), ne jen z patche. Sourozenecká repa (složky vedle posuzovaného repa) smíš
  číst: sdílené knihovny (`Infrastructure`, `shared-packages`, `fullsys-brokers` …) i **producenty a konzumenty**
  zpráv, které změna posílá nebo přijímá (task-manager, manufactory …). Posuzuješ-li starší commit (review cizího PR),
  čti sourozence ve stavu k datu toho commitu (`git -C <repo> show <commit před datem>:<soubor>`), ať review
  „nevidí budoucnost“.
- **U každé netriviální změny si polož tři otázky** z obecných oblastí. Kalibrace ukázala, že právě tady review
  chyby míjelo:
  1. Odkud se kód volá a co na té cestě chybí (fronta = žádný uživatel)?
  2. Projde nový typ nebo pole obecným mechanismem (filtr, deserializace)?
  3. Co se stane s daty, která už v databázi jsou?
- Drž **pravidlo důkazu** a **pořadí vrstev** z `obecna-pravidla.md`. Co vypíná `## Neřeš` v `REVIEW.md`,
  nehlásíš.
- Rozpor mezi zdroji kritérií neřeš potichu: řiď se vyšší vrstvou a rozpor uveď jako ℹ️ info.
- **`CRITERIA_CHANGED` není `none`:** uveď to v hlavičce výstupu. Hodnoť podle **nové** verze kritérií
  a každé uvolnění pravidla nahlas jako ℹ️ info.
- Velký diff (víc než ~60 souborů): řekni to a nabídni zúžení (konkrétní složka, jiná base). Paralelní
  subagenty spouštěj jen na výslovné přání uživatele.

### 4. Vypiš nálezy

Do terminálu, v tomto tvaru:

```markdown
**Review `<repo>` proti `<BASE>`** · <N> souborů (+X/−Y) · kontrakt: REVIEW.md v1 | žádný · <A> autorit, <M> pravidel · <SKIPPED> vynechaných
⚠️ <každé WARN= zvlášť>
⚠️ Změna mění kritéria review: <CRITERIA_CHANGED>      ← jen když není none

| # | Závažnost | Soubor | Problém | Pravidlo |
|---|---|---|---|---|
| 1 | 🟠 high | `src/…/FooProcessor.cs:42` | Jedna věta | `REVIEW.md` › Event processory |

1. <nejvýš 4 řádky: co je špatně, proč na tom záleží, jak to opravit>

**Souhrn:** 🔴 0 · 🟠 1 · 🟡 0 · 🟢 0 · ℹ️ 0
```

- Sloupec **Pravidlo** je povinný: konkrétní soubor a sekce, ze kterých nález plyne. Obecná pravidla
  ze skillu uváděj jako `obecné › <pravidlo>`, baseline jako `PPS baseline › <pravidlo>`.
  Nález, ke kterému neumíš uvést zdroj, nevypisuj.
- Číslo řádku ber z anotace patche (nový řádek), ne z hlavičky `@@`.
- **Bez limitu počtu nálezů.** Lokálně chce autor vidět všechno, včetně 🟢 low.
- Nenašel-li jsi nic, napiš to jednou větou a nevymýšlej výplň.
- Na konci jednou větou: review je jen v terminálu, nic se nepublikovalo.

---

## Hranice

- **Nic nepublikuj a necommituj.** Žádný `git commit`, `git push`, komentář do PR ani zápis do Jiry.
- **Neopravuj nálezy**, dokud o to uživatel nepožádá. Review a oprava jsou dva kroky.
- **Do repa nic nezapisuj**, ani `REVIEW.md`. Chybí-li, nabídni jeho návrh skillem `review-init`.
- Narazíš-li v diffu na credentials, hodnotu nereprodukuj: uveď typ a místo, doporuč rotaci a nález označ 🔴.
- Lokální review **nenahrazuje** review na PR. Nikdo kromě autora ho nevidí.
