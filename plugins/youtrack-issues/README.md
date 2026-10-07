# YouTrack Issues

Skilly pro zakládání issue v YouTracku Fullsys. Skill obsahuje jen tenké instrukce; pravidla, šablona
a příklady jsou v knowledge base YouTracku a skill si je načte při každém spuštění.

| Skill | Výsledek | Metodika v KB |
| --- | --- | --- |
| `/create-bug-issue` | issue `Bug` ve stavu `Open` | QA: Zakládání Bugu (pro AI agenta) |
| `/create-issue` | issue `User Story` ve stavu `Open` | QA: Zakládání User Story (pro AI agenta) |

## Požadavky

- nainstalovaný plugin [youtrack-fullsys](../youtrack-fullsys/) a nastavená proměnná `YT_FULLSYS_TOKEN`
- práva zakládat issue v cílovém projektu

## Instalace

```
/plugin install youtrack-fullsys@fullsys-plugins
/plugin install youtrack-issues@fullsys-plugins
```

## Použití

```
/create-bug-issue
/create-bug-issue Polabské hlásí, že terminál při naskladnění hlásí „Šarže je povinná“, HD-4521
/create-issue Skladníci chtějí na terminálu dělit palety
```

Agent se doptá na chybějící údaje, dohledá související issue, ukáže draft a issue založí až po potvrzení.

## Změny pravidel

Pravidla se mění v knowledge base, ne v tomto pluginu. Podněty zapisujte do komentáře článku
*QA: Zakládání issue v YouTracku (pro AI agenta)*.
