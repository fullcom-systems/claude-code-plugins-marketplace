---
name: create-bug-issue
description: >-
  Použij, když uživatel našel chybu a chce ji založit jako Bug v YouTracku
  Fullsys — z vlastního popisu, e-mailu zákazníka, HD požadavku, logu nebo
  neúspěšného testu. Založíš Bug podle metodiky v knowledge base, vždy až po
  potvrzení draftu uživatelem. Nepoužívej pro požadavky na novou funkčnost
  (na to je /youtrack-fullsys:create-user-story) ani pro úpravu existujících
  issue.
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

**Když metodiku nenačteš, skonči.** Bez ní issue nezakládej ani nenavrhuj. Uživateli řekni, co přesně selhalo:

* **Nástroje MCP serveru `youtrack` nejsou dostupné:** server se nenačetl. Nejčastěji chybí
  proměnná `YT_FULLSYS_TOKEN`. Ať ji nastaví a restartuje Claude Code.
* **Server vrací chybu autentizace (401):** token je neplatný nebo expirovaný. Ať vygeneruje
  nový a restartuje Claude Code.
* **Server funguje, ale článek nejde načíst** (403, nenalezen podle ID ani podle názvu):
  uveď ID a název článku. Uživatel nemá přístup do knowledge base projektu NIN, nebo byl článek
  přesunut či smazán. Ať si ověří přístup u správce KB. Token neměnit.

## 2. Postupuj podle metodiky

* **Bez argumentu:** zeptej se na chybějící údaje podle seznamu povinných údajů v článku Bug.
  Když v článku takový seznam nenajdeš, skonči a řekni uživateli, že metodika je neúplná.
* **S argumentem:** použij ho jako vstup a ptej se jen na to, co v něm chybí.
* Dodrž postup z nadřazeného článku: ptaní → hledání souvisejícího → draft → **potvrzení** → založení.
  Bez výslovného potvrzení draftu uživatelem nic nezakládej.

## 3. Výstup

Po založení vrať ID, odkaz `https://youtrack.fullsys.cz/issue/<ID>` a seznam polí nebo linků, které se
nepodařilo nastavit.

Když uživatel s výsledkem není spokojený a jde o chybu metodiky (ne o jeden případ), navrhni mu zapsat
podnět do komentáře článku *QA: Zakládání issue v YouTracku (pro AI agenta)*.
