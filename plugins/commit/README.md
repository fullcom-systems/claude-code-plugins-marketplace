# commit

Commit Message Generator — Claude Code skill pro vytváření commit zpráv podle Conventional Commits a interních konvencí projektu NextFIS.

## Skill: `/commit`

Skill generuje commit zprávy a může provést commit změn v repozitáři.

| Vstup | Popis |
|-------|-------|
| Popis změn | Ruční popis, co se změnilo |
| Ticket / větev | Ticket se extrahuje z `$GIT_BRANCH_NAME` nebo `git branch --show-current` |

## Konvence

- **Type a scope** — anglicky (`feat`, `fix`, `api`, `db`, …)
- **Subject a body** — česky, subject v imperativu
- **Footer** — `Refs:` / `Fixes:` s ID ticketu z větve (např. `INO-153`, `RF-456`)

Referenční příklady commit zpráv jsou v `skills/commit/EXAMPLE.md`.

## Instalace

```
/plugin install commit
```

## Příklady použití

```
/commit
/commit přidej podporu pro Seq logging
/commit RF-456
```

## Changelog

### 1.0.0

- Počáteční vydání skilu commit
- Conventional Commits s interními konvencemi NextFIS
- Extrakce ticketu z názvu větve
