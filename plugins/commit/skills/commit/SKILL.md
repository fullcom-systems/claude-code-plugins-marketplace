---
name: commit
description: >-
  Použij, když uživatel požaduje vytvoření commitu, napsání commit zprávy nebo
  commitnutí změn. Generuješ zprávy podle Conventional Commits s interními
  konvencemi NextFIS — český subject v imperativu, anglický type a scope,
  extrakce ticketu z názvu větve. Nepoužívej pro review kódu ani změny bez
  commitu.
user-invocable: true
argument-hint: [popis změn nebo ticket]
---

# Commit Message Generator

Tento skill generuje commit zprávy podle Conventional Commits a interních konvencí projektu NextFIS.

## Formát commit zprávy

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## Pravidla

### 1. Type (anglicky)

Povolen jeden z: `feat` | `fix` | `perf` | `refactor` | `docs` | `test` | `style` | `build` | `ci` | `chore` | `revert`

| Type | Použití |
|------|---------|
| feat | Nová funkcionalita |
| fix | Oprava chyby |
| perf | Optimalizace výkonu |
| refactor | Změna kódu bez změny chování |
| docs | Dokumentace |
| test | Testy |
| style | Formátování, whitespace |
| build | Build systém, závislosti |
| ci | CI/CD konfigurace |
| chore | Údržba, pomocné skripty |
| revert | Reverze předchozího commitu |

### 2. Scope (anglicky)

Krátký identifikátor oblasti: `api`, `gateway`, `db`, `ci`, `infra`, `telemetry`, `warehouse`, `android`, `domain`, `mobile`, `web` atd.

### 3. Subject (česky)

- **Imperativ** (rozkazovací způsob): "přidej", "oprav", "uprav" (ne "přidáno", "opraveno")
- **Malými písmeny** (bez velkého písmene na začátku)
- **Bez tečky** na konci
- **Max ~72 znaků**

### 4. Body (volitelné, česky)

- Co a PROČ se změnilo
- Dopady změny
- Zvažované alternativy
- Formát: krátké odrážky, řádky do ~100 znaků

### 5. Footer (volitelné)

- `Refs: ISSUE-ID` – odkaz na issue/ticket
- `Fixes: ISSUE-ID` – jen při opravě chyby (uzavře issue)
- `BREAKING CHANGE:` – popis breaking change
- `Co-authored-by: Name <email>` – spoluautor
- `SemVer: major|minor|patch` – explicitní určení verze

### 6. Extrakce čísla tiketu

Pokud existuje proměnná `$GIT_BRANCH_NAME` nebo je známý název větve, extrahuj z něj číslo tiketu:

- `feature/INO-153-fefo-allocator` → `INO-153`
- `fix/RF-456-login-bug` → `RF-456`
- `bugfix/AOPTIMIZE-1` → `AOPTIMIZE-1`

## Postup vytvoření commitu

1. **Zjisti stav repozitáře**:
   ```bash
   git status
   git diff --staged
   git branch --show-current
   ```

2. **Analyzuj změny**:
   - Jaké soubory se změnily?
   - Jaký je charakter změny (nová funkce, oprava, refaktoring...)?
   - Jaký scope odpovídá změnám?

3. **Extrahuj ticket** z názvu větve (pokud existuje)

4. **Vytvoř commit zprávu** podle pravidel

5. **Proveď commit**:
   ```bash
   git add <soubory>
   git commit -m "$(cat <<'EOF'
   <type>(<scope>): <subject>

   - detail změny 1
   - detail změny 2

   Refs: TICKET-ID
   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   EOF
   )"
   ```

## Kontrolní seznam

Před vytvořením commitu ověř:

- [ ] Správný type odpovídající charakteru změny?
- [ ] Scope odpovídá dotčeným souborům/oblastem?
- [ ] Subject ≤ 72 znaků, imperativ, bez tečky?
- [ ] Subject i body česky (type a scope anglicky)?
- [ ] Breaking change má `BREAKING CHANGE:` ve footeru?
- [ ] Ticket reference ve footeru (pokud existuje)?

## Příklad

Kompletní příklad commit zprávy najdeš v souboru `EXAMPLE.md` ve stejném adresáři jako tento skill.
