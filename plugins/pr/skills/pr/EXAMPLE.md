# Příklad vyplněné PR šablony

> `<issue-tracker-url>` nahraď základní URL issue trackeru projektu (Jira, YouTrack, GitHub Issues, Azure Boards…). Řádek `Verze:` uveď jen, pokud projekt verzuje release.

## Příklad 1: Nová funkce

```markdown
**[PROJ-354](<issue-tracker-url>/PROJ-354)**

Verze: **1.4.0**

## Popis změn
- přidán export sestavy do formátu CSV
- doplněna volba oddělovače v dialogu exportu

## Typ změny

- [ ] Bugfix
- [x] Nová funkce
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

- [x] Manuální test v UI
- [ ] Manuální test v terminálu
- [ ] Unit test
- [ ] Integrační / API test

### Popis testu
Test popsaný v PROJ-354
```

## Příklad 2: Bugfix s migrací

```markdown
**[ABC-228](<issue-tracker-url>/ABC-228)**

Verze: **1.3.2**

## Popis změn
- opravena chyba při ukládání duplicitního záznamu
- upravena validace formuláře registrace

## Typ změny

- [x] Bugfix
- [ ] Nová funkce
- [ ] Refactoring
- [ ] Jiná změna (uveď níže)

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [x] Migrace databáze
- [ ] Změny konfigurace
- [ ] Změna API rozhraní
- [ ] Přidává nové závislosti
- [ ] Změna dokumentace

## Testování

- [x] Manuální test v UI
- [ ] Manuální test v terminálu
- [x] Unit test
- [ ] Integrační / API test

### Popis testu
1. Vytvořit záznam s existujícím klíčem
2. Ověřit korektní chybové hlášení místo pádu
3. Ověřit aplikaci migrace na čisté databázi
```

## Příklad 3: Refaktoring

```markdown
**[XY-153](<issue-tracker-url>/XY-153)**

Verze: **2.0.0**

## Popis změn
- rozdělena monolitická service na menší komponenty
- sjednoceno chybové zpracování napříč vrstvou API

## Typ změny

- [ ] Bugfix
- [ ] Nová funkce
- [x] Refactoring
- [ ] Jiná změna (uveď níže)

## Dopady

- [ ] Breaking changes (rozbije zpětnou kompatibilitu)
- [ ] Migrace databáze
- [ ] Změny konfigurace
- [x] Změna API rozhraní
- [ ] Přidává nové závislosti
- [ ] Změna dokumentace

## Testování

- [x] Manuální test v UI
- [ ] Manuální test v terminálu
- [x] Unit test
- [x] Integrační / API test

### Popis testu
Kompletní regresní testy dle testovacího scénáře v XY-153
```

## Příklad 4: Změna bez ticketu

```markdown
**Aktualizace dokumentace**

## Popis změn
- aktualizován CHANGELOG pro poslední release
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
- [ ] Změny konfigurace
- [ ] Změna API rozhraní
- [ ] Přidává nové závislosti
- [x] Změna dokumentace

## Testování

- [ ] Manuální test v UI
- [ ] Manuální test v terminálu
- [ ] Unit test
- [ ] Integrační / API test

### Popis testu
Není třeba - pouze dokumentace
```
