---
name: create-user-story
description: >-
  Použij, když analytik, zadavatel nebo podpora potřebuje v YouTracku Fullsys
  založit požadavek na novou funkčnost nebo změnu chování. Založíš User Story
  podle metodiky v knowledge base, vždy až po potvrzení draftu uživatelem.
  Nepoužívej pro chyby v dodané funkci (na to je
  /youtrack-fullsys:create-bug-issue) ani pro úpravu existujících issue.
argument-hint: "[popis požadované funkčnosti]"
---

# Založení User Story v YouTracku Fullsys

Pravidla nejsou v tomto souboru. Jsou v knowledge base YouTracku a mění se tam. **Vždy je načti znovu,
nepoužívej verzi z paměti ani z dřívější konverzace.**

## 1. Načti metodiku

Přes MCP server `youtrack` (součást tohoto pluginu) načti celý obsah těchto článků, v tomto pořadí:

1. `NIN-A-493` — *QA: Zakládání issue v YouTracku (pro AI agenta)*
2. `NIN-A-495` — *QA: Zakládání User Story (pro AI agenta)*

Když článek podle ID nenajdeš, vyhledej ho v knowledge base podle přesného názvu.

**Když MCP server `youtrack` není dostupný nebo se článek nepodaří načíst, skonči** a řekni uživateli,
že je potřeba nastavit proměnnou `YT_FULLSYS_TOKEN` a restartovat Claude Code. Bez metodiky
issue nezakládej ani nenavrhuj.

## 2. Postupuj podle metodiky

* **Bez argumentu:** zeptej se na chybějící údaje podle článku User Story.
* **S argumentem:** použij ho jako vstup a ptej se jen na to, co v něm chybí.
* Dodrž postup z nadřazeného článku: ptaní → hledání souvisejícího → draft → **potvrzení** → založení.
  Bez výslovného potvrzení draftu uživatelem nic nezakládej.

## 3. Výstup

Po založení vrať ID, odkaz `https://youtrack.fullsys.cz/issue/<ID>` a seznam polí nebo linků, které se
nepodařilo nastavit.

Když uživatel s výsledkem není spokojený a jde o chybu metodiky (ne o jeden případ), navrhni mu zapsat
podnět do komentáře článku *QA: Zakládání issue v YouTracku (pro AI agenta)*.
