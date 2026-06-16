---
name: pr
description: >-
  Použij, když uživatel požaduje vytvoření pull requestu, otevření PR nebo merge
  request. Vyplníš šablonu PR podle konvencí NextFIS, analyzuješ všechny commity od
  masteru a extrahuješ ticket z názvu větve. Nepoužívej pro review kódu ani merge
  bez vytvoření PR.
user-invocable: true
argument-hint: [ticket nebo stručný popis změn]
---

# Pull Request Generator

Tento skill vytváří pull requesty podle šablony projektu NextFIS.

## Postup vytvoření PR

1. **Zjisti stav repozitáře**:
   ```bash
   git status
   git branch --show-current
   git log master..HEAD --oneline
   git diff master...HEAD
   ```

2. **Extrahuj ticket z názvu větve**:
   - `feature/INO-153-fefo-allocator` → `INO-153`
   - `fix/RF-456-login-bug` → `RF-456`
   - `bugfix/EXP-354` → `EXP-354`

3. **Analyzuj všechny změny** (všechny commity od masteru, ne jen poslední):
   - Jaké soubory se změnily?
   - Jaký je charakter změny?
   - Jsou breaking changes?
   - Jsou migrace databáze?
   - Změnila se konfigurace?

4. **Vyplň šablonu PR** podle pravidel níže

5. **Vytvoř PR pomocí gh CLI**

## Formát PR

```markdown
**[TICKET](https://youtrack.fullsys.cz/issue/TICKET)**

Verze: **YY.MM.build.revision**

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
- [ ] Změny konfigurace (appsettings.json, web.config)
- [ ] Změna API rozhraní
- [ ] Přidává nové NuGet balíčky
- [ ] Změnu dokumentace

## Testování

- [ ] Manuální test ve WEB UI
- [ ] Manuální test v terminálu
- [ ] Unit test
- [ ] HTTP testy

### Popis testu
Krátký popis jak testovat nebo odkaz na ticket.
```

## Pravidla pro vyplnění

### Ticket a odkaz

- Extrahuj ticket z názvu větve
- Formát: `**[TICKET](https://youtrack.fullsys.cz/issue/TICKET)**`
- Pokud není ticket, použij obecný název změny bez odkazu

### Verze

- Formát: `YY.MM.build.revision` (např. `26.01.1.10`)
- Pokud se verze nezměnila, ponech předchozí nebo se zeptej

### Popis změn

- **Stručný a přesný** — každá odrážka max 1 věta
- Popisuj CO se změnilo, ne JAK
- Bez technických detailů implementace
- Česky

### Typ změny

Označ křížkem `[x]` jeden typ:
- **Bugfix** — oprava chyby
- **Nová funkce** — nová funkcionalita
- **Refactoring** — změna kódu bez změny chování
- **Jiná změna** — dokumentace, konfigurace, atd.

### Dopady

Označ křížkem `[x]` vše co platí:
- **Breaking changes** — rozbije zpětnou kompatibilitu
- **Migrace databáze** — přidány/změněny migrace EF
- **Změny konfigurace** — appsettings.json, web.config
- **Změna API rozhraní** — změna endpointů, DTOs
- **Přidává nové NuGet balíčky** — nové závislosti
- **Změnu dokumentace** — README, CHANGELOG, atd.

### Testování

Označ způsoby testování a přidej krátký popis nebo odkaz na ticket.

## Vytvoření PR

```bash
gh pr create --base master --title "TICKET: Stručný název" --body "$(cat <<'EOF'
<vyplněná šablona>
EOF
)"
```

## Kontrolní seznam

- [ ] Ticket extrahován z větve?
- [ ] Verze aktualizována?
- [ ] Popis změn stručný a přesný?
- [ ] Správný typ změny označen?
- [ ] Všechny dopady označeny?
- [ ] Způsob testování uveden?

## Příklad

Kompletní příklad vyplněné šablony najdeš v souboru `EXAMPLE.md` ve stejném adresáři jako tento skill.
