# Příklad vyplněné PR šablony

## Příklad 1: Nová funkce

```markdown
**[EXP-354](https://youtrack.fullsys.cz/issue/EXP-354)**

Verze: **26.01.1.10**

## Popis změn
- nyní na terminálu nelze zpracovávat stornovanou paletu
- přidána kontrola zrušeného binu

## Typ změny

- [ ] Bugfix
- [x] Nová funkce
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
- [x] Manuální test v terminálu
- [ ] Unit test
- [ ] HTTP testy

### Popis testu
Test popsaný v EXP-354
```

## Příklad 2: Bugfix s migrací

```markdown
**[INO-228](https://youtrack.fullsys.cz/issue/INO-228)**

Verze: **26.01.1.8**

## Popis změn
- opravena chyba při příjmu palet z externího skladu
- upravena validace v úloze Obecný příjem zboží a materiálu

## Typ změny

- [x] Bugfix
- [ ] Nová funkce
- [ ] Refactoring
- [ ] Jiná změna (uveď níže)

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [x] Migrace databáze
- [ ] Změny konfigurace (appsettings.json, web.config)
- [ ] Změna API rozhraní
- [ ] Přidává nové NuGet balíčky
- [ ] Změnu dokumentace

## Testování

- [ ] Manuální test ve WEB UI
- [x] Manuální test v terminálu
- [x] Unit test
- [ ] HTTP testy

### Popis testu
1. Vytvořit paletu v externím skladu
2. Provést příjem do hlavního skladu
3. Ověřit správné přiřazení binu
```

## Příklad 3: Refaktoring

```markdown
**[INO-153](https://youtrack.fullsys.cz/issue/INO-153)**

Verze: **26.01.1.5**

## Popis změn
- implementován FEFO alokátor šarží
- refaktoring fáze 1b dokončen

## Typ změny

- [ ] Bugfix
- [ ] Nová funkce
- [x] Refactoring
- [ ] Jiná změna (uveď níže)

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [ ] Migrace databáze
- [ ] Změny konfigurace (appsettings.json, web.config)
- [x] Změna API rozhraní
- [ ] Přidává nové NuGet balíčky
- [ ] Změnu dokumentace

## Testování

- [x] Manuální test ve WEB UI
- [x] Manuální test v terminálu
- [x] Unit test
- [x] HTTP testy

### Popis testu
Kompletní regresní testy alokace šarží dle testovacího scénáře v INO-153
```

## Příklad 4: Změna bez ticketu

```markdown
**Aktualizace dokumentace**

Verze: **26.01.1.1**

## Popis změn
- aktualizován CHANGELOG pro verzi 26.01
- přidána dokumentace nových API endpointů

## Typ změny

- [ ] Bugfix
- [ ] Nová funkce
- [ ] Refactoring
- [x] Jiná změna (uveď níže)

Dokumentace

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [ ] Migrace databáze
- [ ] Změny konfigurace (appsettings.json, web.config)
- [ ] Změna API rozhraní
- [ ] Přidává nové NuGet balíčky
- [x] Změnu dokumentace

## Testování

- [ ] Manuální test ve WEB UI
- [ ] Manuální test v terminálu
- [ ] Unit test
- [ ] HTTP testy

### Popis testu
Není třeba - pouze dokumentace
```
