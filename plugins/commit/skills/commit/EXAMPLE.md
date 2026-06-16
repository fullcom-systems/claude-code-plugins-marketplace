# Příklady commit zpráv

Tento soubor obsahuje referenční příklady commit zpráv podle konvencí projektu NextFIS.

## Jednoduchý commit (pouze subject)

```
fix(db): oprav index na tabulce registers
```

## Commit s body

```
fix(db): oprav index na tabulce registers

- přidán chybějící index pro rychlejší vyhledávání
- snížení času dotazu z 2s na 200ms

Refs: RF-123
```

## Nová funkcionalita

```
feat(logging): přidej podporu pro Seq

- implementace asynchronního appenderu
- konfigurace přesunuta do Web.config

Refs: RF-456
```

## Optimalizace výkonu

```
perf(sql): optimalizuj dotaz GetStolenOrLosen

- přechod na raw SQL místo LINQ
- snížení času dotazu o 80%

Refs: AOPTIMIZE-1
```

## Refaktoring

```
refactor(queries): uprav uložení a použití UnitOfWork

- konzistentnější práce s databázovým kontextem
- odstranění duplicitního kódu

Refs: RF-789
```

## Breaking change

```
feat(api): změň formát odpovědi endpointu /bins

- nový formát obsahuje pagination metadata
- pole items místo přímého pole

BREAKING CHANGE: Odpověď endpointu GET /bins nyní vrací objekt s polem items místo přímého pole. Všichni klienti musí aktualizovat parsování.

Refs: API-100
```

## Více souborů/oblastí

```
refactor(warehouse,domain): extrahuj validaci do samostatné služby

- nová třída BatchValidationService
- použití ve všech handlers
- jednotné chybové hlášky

Refs: INO-200
```

## Commit bez ticketu

```
docs(readme): aktualizuj instalační instrukce

- přidán krok pro nastavení MariaDB
- opraveny zastaralé příkazy
```

## Chore/údržba

```
chore(deps): aktualizuj NuGet balíčky

- MediatR 12.0 → 12.1
- FluentValidation 11.5 → 11.6
```

## CI/CD změny

```
ci(docker): optimalizuj build image

- multi-stage build pro menší výsledný image
- cache NuGet restore vrstvy
```
