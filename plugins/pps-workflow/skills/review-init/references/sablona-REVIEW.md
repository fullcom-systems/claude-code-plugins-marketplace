---
review-kontrakt: 1
base: dev-sprint
# vynechat:            # jen soubory NAVÍC k výchozím (lock soubory, Migrations/*.Designer.cs, *ModelSnapshot.cs)
#   - "**/*.generated.cs"
---
<!--
  Šablona REVIEW.md pro mikroslužby PPS G2 (kontrakt v1).
  Kontrakt v1 shrnuje SKILL.md skillu review-init, sekce „Pravidla kontraktu“.
  Zkopíruj do kořene repa jako REVIEW.md a vyplň. Komentáře <!-- --> pak smaž.
  Limit: 200 řádků (cíl 150). Pravidla sem neopisuj, jen na ně odkazuj.
-->
# Review kritéria – <název služby>

Čte ho skill `review-lokalne`. Říká, na co se v tomhle repu zaměřit **navíc** k PPS baseline a obecným
pravidlům skillu. Pravidla drží autority níž. **Tenhle soubor je neopisuje**, kalibruje jen závažnost,
zaměření a výjimky.

## Autority

<!-- Soubory, které drží pravidla repa. Skill je čte vždy. U každého jedna věta, co v něm je. -->

- [`CLAUDE.md`](CLAUDE.md) – architektura, vrstvy, pojmenování, testy.
- [`<cesta>`](<cesta>) – <co drží>.

## Co číst podle změněné cesty

<!--
  Volitelné. Jen pro zdroje BEZ frontmatteru `paths:` (znalostní skilly, specifikace chování, dokumenty).
  Pravidla s `paths:` v .claude/rules nebo .ai-rulez/rules najde skill sám, sem je nepiš.
  Globy se sčítají: soubor může spadat pod víc řádků. Glob je permisivní: `*` zasáhne i `/`, `**/` i nula složek.
  Glob, který nesedí na žádný soubor v gitu, skript nahlásí. Na generované cesty (.agents/) neodkazuj.
-->

| Zdroj | Platí pro | Poznámka |
|---|---|---|
| [`.claude/skills/<skill>/SKILL.md`](.claude/skills/<skill>/SKILL.md) | `src/<Projekt>.Application/**/*.cs` | <proč> |
| [`openspec/specs/<capability>/spec.md`](openspec/specs/<capability>/spec.md) | `src/**/<Agregát>/**` | chování, které změna nesmí tiše rozbít |

## Závažnost

<!--
  Škála je pro celé PPS pevná, nové úrovně nepřidávej. Doplň PŘÍKLADY z tohoto repa.
  Nesedí-li nález do žádné úrovně, není to nález.
-->

| Závažnost | Kategorie | Příklady v tomto repu |
|---|---|---|
| 🔴 critical | únik dat nebo bezpečnost s okamžitým dopadem | <např. endpoint bez autorizace> |
| 🟠 high | tiché chybné chování v produkci, eroze architektury | <např. processor, který při chybě event potichu zahodí> |
| 🟡 medium | nesoulad, který někoho zavede, ale kód funguje | <např. čtení přes repository místo query> |
| 🟢 low | konvence bez dopadu na chování | <např. chybějící XML summary na rozhraní> |
| ℹ️ info | upozornění bez nálezu | <např. rozdíl proti Confluence> |

## Na co se zaměřit

<!--
  Jen to, co v autoritách NENÍ, nebo co review musí hlídat zvlášť přísně.
  Jedna podsekce = jedna oblast. Tvar položky: co hlídat – závažnost, důkaz nebo odkaz na autoritu › sekci, výjimky.
  Pravidlo autority nepřevyprávěj, jen ho kalibruj. Každá položka musí být ověřená v kódu.
    ✅ Processor výjimku propaguje (`throw;`) – 🟠, 84/84 processorů, `CLAUDE.md` › Přehled projektu
    ❌ odstavec, který vlastními slovy převypráví sekci AGENTS.md
-->

### <Oblast, např. Event processory>

- <co hlídat> – <závažnost>, <důkaz / odkaz na autoritu › sekci>, <výjimky>

### <Oblast, např. Persistence>

- <co hlídat>

## Pravidlo důkazu

<!-- Volitelné. Jen ZPŘÍSNĚNÍ obecného pravidla skillu, uvolnit ho nejde. Jinak sekci smaž. -->

## Co v kódu ještě není

<!-- Volitelné. Rozhodnuté, ale neimplementované. Absence položky odtud není nález. -->

## Neřeš

<!--
  Nesmí chybět. Co není nález: vědomá rozhodnutí, zapsané dluhy, výjimky
  a vše, co SKUTEČNĚ hlídá build, test nebo Sonar. Styl z .editorconfig build hlídá jen s EnforceCodeStyleInBuild
  (inventura to uvádí); jinak zvol druhou variantu řádku níž.
-->

- Formátování podle `.editorconfig` – nález jen tam, kde mění chování. <!-- nebo: „…vynucuje build (EnforceCodeStyleInBuild)“ -->
- Zvýšení `<Version>` v `<projekt>.csproj`. Patří ke každému PR. <!-- jen když to inventura ukáže -->
- Pravidla, která vypíná `vynechat-pravidla:` ve frontmatteru, sem znovu nepiš.
- <vědomé rozhodnutí> – <odkaz na důvod>
