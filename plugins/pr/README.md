# pr

Pull Request Generator — Claude Code skill pro vytváření pull requestů podle strukturované šablony.

## Skill: `/pr`

Skill analyzuje změny na větvi, vyplní šablonu PR a vytvoří pull request přes `gh` CLI.

| Vstup | Popis |
|-------|-------|
| Popis změn | Ruční popis nebo analýza z git diff |
| Ticket / větev | Ticket se extrahuje z názvu větve (např. `PROJ-153`, `ABC-456`) |

## Šablona PR

- Odkaz na ticket v issue trackeru projektu
- Verze (volitelně, pokud projekt verzuje)
- Popis změn, typ změny, dopady a testování

Referenční příklady vyplněné šablony jsou v `skills/pr/EXAMPLE.md`.

## Instalace

```
/plugin install pr
```

## Příklady použití

```
/pr
/pr PROJ-153
/pr vytvoř pull request pro opravu validace
```

## Changelog

Viz [CHANGELOG.md](CHANGELOG.md).
