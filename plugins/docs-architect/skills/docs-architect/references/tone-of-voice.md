# Tón dokumentace podle cílové skupiny

Meta-shrnutí: Referenční pravidla, jakým tónem psát pro každou cílovou složku, s příklady „špatně vs. dobře". Cílová skupina: Claude při psaní těla dokumentu.

## Obsah

- [Proč na tónu záleží](#proč-na-tónu-záleží)
- [docs/support – netechnická podpora](#docssupport--netechnická-podpora)
- [docs/development a docs/devops – technické publikum](#docsdevelopment-a-docsdevops--technické-publikum)
- [README a CONTRIBUTING – smíšené publikum](#readme-a-contributing--smíšené-publikum)

## Proč na tónu záleží

Stejná informace musí být napsaná jinak pro DevOps inženýra a jinak pro pracovníka podpory. Špatně zvolený tón dokument znehodnotí: podpora se ztratí v žargonu, vývojář se utopí ve zbytečném vysvětlování. Tón se proto řídí **složkou** (= cílovou skupinou), ne tvým momentálním zvykem.

## docs/support – netechnická podpora

Piš polopaticky, vlídně, bez žargonu. Předpokládej, že čtenář nezná interní názvy systémů ani technické zkratky. Postupy rozepiš krok za krokem, pojmy vysvětli při prvním použití. Cíl: čtenář úkol zvládne sám, bez eskalace na vývoj.

**Špatně (žargon, předpoklady znalostí):**

> Pokud RabbitMQ consumer hodí dead-letter, přečti payload a rekonzumuj zprávu z DLQ.

**Dobře (polopaticky, krok za krokem):**

> Když se objednávka „zasekne" a nezpracuje, znamená to, že systém zprávu odložil stranou. Postupujte takto:
>
> 1. Otevřete administraci v sekci **Fronta zpráv**.
> 2. Najděte odloženou zprávu podle čísla objednávky.
> 3. Klikněte na **Zpracovat znovu**.
>
> Pokud se to opakuje, kontaktujte vývojový tým s číslem objednávky.

> [!TIP]
> V `docs/support/` raději jedna věta navíc než jedna zkratka navíc.

## docs/development a docs/devops – technické publikum

Piš úderně, technicky, bez vaty. Předpokládej zkušeného vývojáře/DevOps. Těžiště je v přesných ukázkách kódu, příkazech a konkrétních hodnotách. Zkratky a názvy technologií používej běžně (DI, CI/CD, FIFO, DLQ). Vynech vysvětlování základních pojmů.

**Špatně (vata, vysvětlování samozřejmostí):**

> Abychom mohli aplikaci nasadit, je potřeba nejprve provést build, což je proces, při kterém se zdrojový kód přeloží...

**Dobře (úderně, konkrétně):**

> Build a deploy přes Azure DevOps pipeline:
>
> ```bash
> dotnet build -c Release
> dotnet ef database update --connection "<CONNECTION_STRING>"
> ```
>
> Pipeline definice: [`azure-pipelines.yml`](../../azure-pipelines.yml). Trigger na `main`, gate na úspěšné testy.

> [!IMPORTANT]
> Technické publikum ocení přesnost. Uváděj konkrétní názvy souborů, příkazy a parametry – ne obecné popisy „nastavte konfiguraci".

## README a CONTRIBUTING – smíšené publikum

README čte úplně každý (i netechnický). Drž úvod stručný a srozumitelný, technické detaily přesuň přes rozcestník do `docs/`. CONTRIBUTING cílí na vývojáře, takže může být technický, ale onboarding-friendly – nový člověk podle něj musí projekt rozjet bez ústní pomoci.
