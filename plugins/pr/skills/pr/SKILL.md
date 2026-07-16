---
name: pr
description: >-
  Použij, když uživatel požaduje vytvoření pull requestu, otevření PR nebo merge
  request. Vyplníš strukturovanou šablonu PR, analyzuješ všechny commity od výchozí
  větve a extrahuješ ticket z názvu větve. Nepoužívej pro review kódu ani merge
  bez vytvoření PR.
user-invocable: true
argument-hint: "[ticket-nebo-popis]"
---

# Pull Request Generator

Tento skill vytváří pull requesty podle strukturované šablony (ticket, popis změn, typ, dopady, testování).

## Postup vytvoření PR

1. **Zjisti stav repozitáře a výchozí větev** (`main`/`master` nehádej — zjisti):
   ```bash
   git status
   git branch --show-current
   BASE=$(basename "$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)")
   BASE=${BASE:-master}   # fallback; pokud je prázdné, nastav origin/HEAD: git remote set-head origin -a
   git log "$BASE"..HEAD --oneline
   git diff "$BASE"...HEAD
   ```

2. **Extrahuj ticket z názvu větve** (vzor `<prefix>/<KLÍČ-ČÍSLO>-<popis>`):
   - `feature/PROJ-153-new-endpoint` → `PROJ-153`
   - `fix/ABC-456-login-bug` → `ABC-456`
   - `bugfix/XY-789` → `XY-789`

3. **Analyzuj všechny změny** (všechny commity od výchozí větve, ne jen poslední):
   - Jaké soubory se změnily?
   - Jaký je charakter změny?
   - Jsou breaking changes?
   - Jsou migrace databáze?
   - Změnila se konfigurace?

4. **Zjisti, zda projekt má vlastní PR šablonu** — projektová šablona má **přednost** před vestavěnou:
   ```bash
   TEMPLATE=$(find .github docs . -maxdepth 1 -iname 'pull_request_template.md' 2>/dev/null | head -1)
   [ -n "$TEMPLATE" ] && echo "Nalezena šablona: $TEMPLATE" && cat "$TEMPLATE"
   ```
   - **Nalezena** → načti její obsah, pochop její pole a vyplň je dle analýzy změn; její strukturu neměň
   - **Nenalezena** → použij vestavěnou šablonu ze sekce „Formát PR" níže
   - Více šablon (`.github/PULL_REQUEST_TEMPLATE/*.md`) → vyber tu, která odpovídá typu změny

5. **Vyplň šablonu PR** (projektovou z kroku 4, jinak vestavěnou dle pravidel níže)

6. **Pushni větev a vytvoř PR pomocí gh CLI** (viz sekce Vytvoření PR)

## Formát PR

> Vestavěná šablona — použij **jen** pokud projekt nemá vlastní PR šablonu (krok 4). Pokud existuje projektová, řiď se jejími poli.

```markdown
**[TICKET](<issue-tracker-url>/TICKET)**

Verze: **X.Y.Z**

## Popis změn
- stručný popis změny 1
- stručný popis změny 2

## Typ změny

- [ ] Bugfix
- [ ] Nová funkce
- [ ] Refactoring
- [ ] Jiná změna (uveď níže)

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [ ] Migrace databáze
- [ ] Změny konfigurace
- [ ] Změna API rozhraní
- [ ] Přidává nové závislosti
- [ ] Změna dokumentace

## Testování

- [ ] Manuální test v UI
- [ ] Manuální test v terminálu
- [ ] Unit test
- [ ] Integrační / API test

### Popis testu
Krátký popis jak testovat nebo odkaz na ticket.
```

## Pravidla pro vyplnění

Platí pro vestavěnou šablonu; u projektové šablony je aplikuj na odpovídající pole (ticket, popis, verze…) a respektuj její strukturu.

### Ticket a odkaz

- Extrahuj ticket z názvu větve
- Formát: `**[TICKET](<issue-tracker-url>/TICKET)**`, kde `<issue-tracker-url>` je základní URL issue trackeru projektu (Jira, YouTrack, GitHub Issues, Azure Boards…)
- Pokud projekt issue tracker nepoužívá nebo ticket neexistuje, použij obecný název změny bez odkazu

### Verze (volitelné)

- Uveď, pouze pokud projekt verzuje release; jinak řádek `Verze:` vynech
- Formát dle konvence projektu (semver `MAJOR.MINOR.PATCH` nebo datový, např. `YY.MM.build.revision`)
- **Zdroj verze** (zjisti, nehádej): soubor s verzí projektu (`package.json`, `*.csproj`, `Directory.Build.props`, `pyproject.toml`…) nebo poslední git tag (`git describe --tags --abbrev=0`)

### Popis změn

- **Stručný a přesný** — každá odrážka max 1 věta
- Popisuj CO se změnilo, ne JAK
- Bez technických detailů implementace
- V jazyce projektu

### Typ změny

Označ křížkem `[x]` jeden typ:
- **Bugfix** — oprava chyby
- **Nová funkce** — nová funkcionalita
- **Refactoring** — změna kódu bez změny chování
- **Jiná změna** — dokumentace, konfigurace, atd.

### Dopady

Označ křížkem `[x]` vše co platí:
- **Breaking changes** — rozbije zpětnou kompatibilitu
- **Migrace databáze** — přidány/změněny migrace schématu
- **Změny konfigurace** — konfigurační soubory, proměnné prostředí
- **Změna API rozhraní** — změna endpointů, DTO, kontraktů
- **Přidává nové závislosti** — nové balíčky/knihovny
- **Změna dokumentace** — README, CHANGELOG, atd.

### Testování

Označ způsoby testování a přidej krátký popis nebo odkaz na ticket.

## Vytvoření PR

1. **Pushni větev** (bez pushnuté větve `gh pr create` selže):
   ```bash
   git push -u origin HEAD
   ```

2. **Zkontroluj, zda PR pro větev už neexistuje** — pokud ano, jen ho aktualizuj (`gh pr edit`) místo vytváření nového:
   ```bash
   gh pr view --json url,state 2>/dev/null   # vrátí-li PR, použij gh pr edit --body ...
   ```

3. **Vytvoř PR proti výchozí větvi** (`$BASE` z kroku 1, ne napevno `master`):
   ```bash
   gh pr create --base "$BASE" --title "TICKET: Stručný název" --body "$(cat <<'EOF'
   <vyplněná šablona>
   EOF
   )"
   ```

## Kontrolní seznam

- [ ] Zkontrolována existence projektové PR šablony?
- [ ] Ticket extrahován z větve?
- [ ] Verze uvedena (pokud projekt verzuje)?
- [ ] Popis změn stručný a přesný?
- [ ] Správný typ změny označen?
- [ ] Všechny dopady označeny?
- [ ] Způsob testování uveden?
