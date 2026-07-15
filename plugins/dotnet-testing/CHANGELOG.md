# Changelog

Všechny významné změny v tomto projektu budou dokumentovány v tomto souboru.

Formát vychází z [Keep a Changelog](https://keepachangelog.com/cs/1.1.0/)
a projekt dodržuje [Semantic Versioning](https://semver.org/lang/cs/).

## [1.1.0] - 2026-07-15

### Added

- Skill `dotnet-http-tests` nově akceptuje a **preferuje deklarativní asserce httpyac `??`**
  (`?? status == 200`, `?? body == true`, `?? body <cesta> == …`, `?? header <název> == …`,
  `?? duration < …`) pro běžné kontroly stavu, těla a hlaviček — vedle dosavadního
  skriptovacího bloku `> {% client.test(...) %}`, který zůstává pro složitější logiku.
  Doplněna tabulka operátorů/predikátů a kompletní ukázka (potvrzení skladových pohybů:
  scénáře 200/400/401).

### Changed

- Sekce „Ukázkový `.http` soubor" přepsána na „Assert bloky — dvě syntaxe (obě akceptované)";
  aktualizován kontrolní seznam i tabulka v `README.md`.

## [1.0.0] - 2026-07-14

### Added

- Počáteční verze pluginu `dotnet-testing`
- Skill `dotnet-unit-tests` — zjistí testovací konvence repozitáře (framework, mock/assert
  knihovny, umístění testů) a generuje/doplňuje unit testy podle AAA patternu s XML dokumentací
  a pojmenováním `{Metoda}_{Scénář}_{Očekávání}`; pro nový testovací projekt navrhuje výchozí
  stack xUnit + NSubstitute + Shouldly (licenčně nezávadná alternativa k Moq/FluentAssertions).
  Doplněn o `SYNTAX.md` (xUnit/NUnit/MSTest, NSubstitute/Moq, Shouldly/FluentAssertions) a
  `EXAMPLE.md` (kompletní referenční příklad na obecné doméně).
- Skill `dotnet-http-tests` — navrhuje strukturu `.http` testů kompatibilní s VS Code REST
  Client, httpyac i IntelliJ HTTP Client, environment soubory s přepínáním local/staging/prod
  (`http-client.env.json` / `http-client.private.env.json`, secrety jen přes `$processEnv`),
  assert bloky httpyac a CI/CD pipeline. Reference `references/azure-devops.md` a
  `references/github-actions.md` s hotovými YAML šablonami (`httpyac send … --junit`,
  publikace JUnit).
- Manifest `.claude-plugin/plugin.json`, `README.md`
