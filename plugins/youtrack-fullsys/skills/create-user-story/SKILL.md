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

**Když metodiku nenačteš, skonči.** Bez ní issue nezakládej ani nenavrhuj. Uživateli řekni, co přesně selhalo:

* **Nástroje MCP serveru `youtrack` nejsou dostupné:** server se nenačetl. Nejčastěji chybí
  proměnná `YT_FULLSYS_TOKEN`. Ať ji nastaví a restartuje Claude Code.
* **Server vrací chybu autentizace (401):** token je neplatný nebo expirovaný. Ať vygeneruje
  nový a restartuje Claude Code.
* **Server funguje, ale článek nejde načíst** (403, nenalezen podle ID ani podle názvu):
  uveď ID a název článku. Uživatel nemá přístup do knowledge base projektu NIN, nebo byl článek
  přesunut či smazán. Ať si ověří přístup u správce KB. Token neměnit.

## 2. Postupuj podle metodiky

Postup, pravidla, formát draftu i výstup jsou v načtených článcích. Při rozporu platí podčlánek.
Bez výslovného potvrzení draftu uživatelem nic nezakládej.
