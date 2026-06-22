---
name: commit-pps
description: Vytvoř standardizovaný semantic git commit podle Conventional Commits specifikace. Analyzuje aktuální diff a určí vhodný type, scope a popis; volitelně s argumentem `push` po commitu provede i `git push`. Použij vždy, když uživatel chce udělat commit, "zacommitovat", "zacommitnout" nebo požádá o commit message.
---

# commit-pps — Conventional Commits

## Účel

Vytvoř standardizovaný, sémantický git commit podle [Conventional Commits](https://www.conventionalcommits.org/) specifikace. Analyzuj skutečný diff a urči vhodný **type**, **scope** a **description**.

## Formát Conventional Commit

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Typy commitů

| Type       | Účel                                        |
|------------|---------------------------------------------|
| `feat`     | Nová funkcionalita                          |
| `fix`      | Oprava bugu                                 |
| `docs`     | Pouze dokumentace                           |
| `style`    | Formátování/styl (bez logiky)               |
| `refactor` | Refactor kódu (bez nové feature/fixu)       |
| `perf`     | Optimalizace výkonu                         |
| `test`     | Přidání/úprava testů                        |
| `build`    | Build systém / závislosti                   |
| `ci`       | CI / konfigurační změny                     |
| `chore`    | Údržba / různé                              |
| `revert`   | Revert commitu                              |

## Breaking Changes

Označuj buď vykřičníkem za typem/scope, nebo footerem `BREAKING CHANGE:`.

```
# Vykřičník za type/scope
feat!: odeber zastaralý endpoint

# BREAKING CHANGE footer
feat: umožnit konfiguraci rozšiřovat jiné konfigurace

BREAKING CHANGE: změněno chování klíče `extends`
```

## Workflow

### 1. Kontrola větve

Zkontroluj aktuální větev (`git branch --show-current`).

Pokud je aktuální větev `dev-sprint`:
- Vyzvi uživatele: "Jsi na dev-sprint. Zadej číslo úkolu a název větve."
- Číslo úkolu a název složí dohromady: `<číslo-úkolu>-<název>`
- Mezery v názvu nahraď pomocí `-`
- Vytvoř větev: `git checkout -b feature/<číslo-úkolu>-<název>`

Pokud je aktuální větev jiná než `dev-sprint` → pokračuj bez změny.

### 2. Analyzuj diff

```bash
# Pokud jsou soubory staged, použij staged diff
git diff --staged

# Pokud není nic staged, použij working tree diff
git diff

# Také zkontroluj status
git status --porcelain
```

### 3. Staguj soubory (pokud je potřeba)

Pokud není nic staged nebo chceš změny seskupit jinak:

```bash
# Staguj konkrétní soubory
git add path/to/file1 path/to/file2

# Staguj podle patternu
git add *.test.*
git add src/components/*

# Interaktivní staging
git add -p
```

**Nikdy necommituj secrets** (`.env`, `credentials.json`, privátní klíče, connection stringy, API tokeny). Pokud je detekuješ v diffu, zastav workflow a upozorni uživatele.

### 4. Vygeneruj commit message

Analyzuj diff a urči:

- **Type** — jaký druh změny to je?
- **Scope** — jaká oblast/modul je dotčen? (volitelné, ale doporučené)
- **Description** — jednořádkové shrnutí (přítomný čas, rozkazovací způsob, **<72 znaků**)

### 5. Proveď commit

```bash
# Jednořádkový
git commit -m "<type>[scope]: <description>"

# Víceřádkový s body/footerem
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<optional body>

<optional footer>
EOF
)"
```

### 6. Push (pouze s argumentem `push`)

Pokud byl skill vyvolán s argumentem `push` (např. `/commit-pps push`), proveď po úspěšném commitu push na remote:

```bash
# Má větev upstream? Pokud ano, prostý push; jinak nastav upstream.
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  git push
else
  git push -u origin "$(git branch --show-current)"
fi
```

- **Bez** argumentu `push` skill nepushuje — končí commitem.
- **Nikdy** nepoužívej `--force` ani `--no-verify` (viz Git Safety Protocol).
- Pokud push selže (rejected, remote nedostupný), **zastav a informuj uživatele** — neřeš rebase/force automaticky.

## Best Practices

- **Jeden logický change na commit**
- **Přítomný čas:** "add" (ne "added")
- **Rozkazovací způsob:** "fix bug" (ne "fixes bug")
- **Description pod 72 znaků**
- Body používej pro vysvětlení **proč**, ne **co** (to je v diffu)

## Příklady commit zpráv
```
feat(orders): přidej filtrování podle projektu a dílu

- Rozšíření OrderListModel o pole Projects a PartsOfCarType
- Přidání $lookup na batches v OrdersQuery
- Filtrování podle čísla a názvu projektu
```
```
fix(auth): oprav expiraci JWT tokenu

- Prodloužení platnosti tokenu z 1 na 24 hodin
- Přidání refresh token logiky do AuthService
```
```
refactor(planning): extrahuj výpočet kapacity do samostatné služby

- Přesun logiky z PlanningController do CapacityCalculator
- Odstranění duplicitního kódu ve třech místech
```

## Git Safety Protocol

- **NIKDY** neupravuj `git config`
- **NIKDY** nespouštěj destruktivní příkazy (`--force`, `git reset --hard`) bez explicitního požadavku uživatele
- **NIKDY** neskipuj hooks (`--no-verify`), pokud o to uživatel nepožádá
- **NIKDY** neforce-pushuj do `main`/`master`
- Pokud commit selže kvůli hookům, **oprav problém a vytvoř NOVÝ commit** (neamenduj)
