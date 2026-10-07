---
name: create-issue
description: >-
  Použij, když analytik, zadavatel nebo podpora potřebuje v YouTracku Fullsys
  založit požadavek na novou funkčnost nebo změnu chování. Agent se doptá na
  chybějící údaje, navrhne akceptační kritéria, dohledá související issue a po
  potvrzení draftu založí User Story ve stavu Open. Nepoužívej pro chyby
  v dodané funkci (na to je /create-bug-issue) ani pro úpravu existujících issue.
user-invocable: true
argument-hint: [popis požadované funkčnosti]
---

# Založení User Story v YouTracku Fullsys

Pravidla jsou v knowledge base YouTracku. **Vždy je načti znovu**, nepoužívej verzi z paměti.

## 1. Načti metodiku

Přes MCP `youtrack` (plugin `youtrack-fullsys`) načti celý obsah, v tomto pořadí:

1. `NIN-A-493` — *QA: Zakládání issue v YouTracku (pro AI agenta)*
2. `NIN-A-495` — *QA: Zakládání User Story (pro AI agenta)*

Článek nenajdeš podle ID → hledej v KB podle přesného názvu.
MCP nebo článek nedostupný → **skonči** a řekni, ať uživatel nainstaluje `youtrack-fullsys` a nastaví `YT_FULLSYS_TOKEN`.

## 2. Postupuj podle metodiky

* Bez argumentu → zeptej se podle článku User Story.
* S argumentem → použij ho, ptej se jen na chybějící.
* Ptaní → hledání souvisejícího → draft → **potvrzení** → založení. Bez potvrzení nic nezakládej.

## 3. Výstup

ID, odkaz `https://youtrack.fullsys.cz/issue/<ID>`, co se nepodařilo nastavit.
Chyba metodiky (ne jednoho případu) → navrhni podnět do komentáře článku *QA: Zakládání issue v YouTracku (pro AI agenta)*.
