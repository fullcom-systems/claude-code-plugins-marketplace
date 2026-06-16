# pr

Pull Request Generator — Claude Code skill pro vytváření pull requestů podle šablony projektu NextFIS.

## Skill: `/pr`

Skill analyzuje změny na větvi, vyplní šablonu PR a vytvoří pull request přes `gh` CLI.

| Vstup | Popis |
|-------|-------|
| Popis změn | Ruční popis nebo analýza z git diff |
| Ticket / větev | Ticket se extrahuje z názvu větve (např. `INO-153`, `RF-456`) |

## Šablona PR

- Odkaz na YouTrack ticket
- Verze ve formátu `YY.MM.build.revision`
- Popis změn, typ změny, dopady a testování

Referenční příklady vyplněné šablony jsou v `skills/pr/EXAMPLE.md`.

## Instalace

```
/plugin install pr
```

## Příklady použití

```
/pr
/pr INO-153
/pr vytvoř pull request pro opravu validace
```

## Changelog

### 1.0.0

- Počáteční vydání skilu pr
- Šablona PR podle konvencí NextFIS
- Extrakce ticketu z názvu větve
- Vytvoření PR přes gh CLI
