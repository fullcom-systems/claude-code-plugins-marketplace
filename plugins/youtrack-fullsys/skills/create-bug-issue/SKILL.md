---
name: create-bug-issue
description: >-
  Použij, když uživatel našel chybu a chce ji založit jako Bug v YouTracku
  Fullsys — z vlastního popisu, e-mailu zákazníka, HD požadavku, logu nebo
  neúspěšného testu. Agent se doptá na chybějící údaje, dohledá související
  issue a po potvrzení draftu založí issue typu Bug ve stavu Open. Nepoužívej
  pro požadavky na novou funkčnost (na to je /youtrack-fullsys:create-user-story)
  ani pro úpravu existujících issue.
user-invocable: true
argument-hint: "[popis chyby, text od zákazníka nebo ID HD požadavku]"
---

# Založení Bugu v YouTracku Fullsys

Pravidla nejsou v tomto souboru. Jsou v knowledge base YouTracku a mění se tam. **Vždy je načti znovu,
nepoužívej verzi z paměti ani z dřívější konverzace.**

## 1. Načti metodiku

Přes MCP server `youtrack` (součást tohoto pluginu) načti celý obsah těchto článků, v tomto pořadí:

1. `NIN-A-493` — *QA: Zakládání issue v YouTracku (pro AI agenta)*
2. `NIN-A-494` — *QA: Zakládání Bugu (pro AI agenta)*

Když článek podle ID nenajdeš, vyhledej ho v knowledge base podle přesného názvu.

**Když MCP server `youtrack` není dostupný nebo se článek nepodaří načíst, skonči** a řekni uživateli,
že je potřeba nastavit proměnnou `YT_FULLSYS_TOKEN` a restartovat Claude Code. Bez metodiky
issue nezakládej ani nenavrhuj.

## 2. Postupuj podle metodiky

* **Bez argumentu:** zeptej se na chybějící údaje podle kap. 2 článku Bug.
* **S argumentem:** použij ho jako vstup a ptej se jen na to, co v něm chybí.
* Dodrž postup z nadřazeného článku: ptaní → hledání souvisejícího → draft → **potvrzení** → založení.
* Nic nezakládej bez výslovného potvrzení draftu uživatelem.

## 3. Výstup

Po založení vrať ID, odkaz `https://youtrack.fullsys.cz/issue/<ID>` a seznam polí nebo linků, které se
nepodařilo nastavit.

Když uživatel s výsledkem není spokojený a jde o chybu metodiky (ne o jeden případ), navrhni mu zapsat
podnět do komentáře článku *QA: Zakládání issue v YouTracku (pro AI agenta)*.
