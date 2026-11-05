# PPS baseline (verze 1)

Společný základ pro všechny mikroslužby PPS G2. Platí, pokud ho `REVIEW.md` repa v sekci `## Neřeš`
výslovně nevypne.

> Obsahuje jen pravidla doložená ve více repech s různou architekturou. Další kandidáti (autorizace
> endpointů, migrace) zatím nejsou ověření a jako pravidla baseline se nehlásí.

## Integrační zprávy a transakce

Doloženo v `planning` (Mongo, `ProduceEventToOutbox` před `CommitChanges`), `technology` (EF + MariaDB,
`Produce(…, dbTransaction)`) a `manufactory` (`AGENTS.md`: zapisující příkaz musí být transakční a produkuje
integrační event).

- Zpráva (event nebo command), která vzniká spolu se zápisem, jde přes outbox **v téže transakci** jako zápis.
  Publikace mimo transakci nebo až po commitu je 🟠 high: data a zpráva se mohou rozejít a ostatní služby
  pak drží jiný stav. Konkrétní mechanismus repa popisuje jeho `REVIEW.md` nebo `AGENTS.md`.
- Výjimku (okamžité odeslání, údržbové přeposlání) musí repo uvést v `## Neřeš`, nebo ji změna zdůvodní.

## Citlivá data a credentials

- Credentials v kódu, konfiguraci, testech nebo skriptech (tokeny, hesla, klíče, connection string
  s heslem) jsou 🔴 critical. Hodnotu nereprodukuj: uveď typ a místo, doporuč rotaci.
- Reálná data zákazníka (osobní údaje, čísla smluv, receptury a technologické postupy) v testech, seed
  datech nebo fixturách jsou 🔴 critical. Patří tam zjevně fiktivní placeholdery.

## Sdílené kontrakty

- Změna verze balíčku sdílených kontraktů (`Fullsys.Pps.EventModels`, balíčky z `shared-packages`)
  v `.csproj` nebo `Directory.Build.props` je ℹ️ info: uveď ji v souhrnu, ať autor ověří dopad na
  konzumenty. Nálezem se stává teprve tehdy, když ji pravidla repa výslovně řadí výš.

## Neřeš (všude)

- Formátování a styl podle `.editorconfig`, pokud nemění chování. Hlídá ho IDE, Sonar, nebo build
  s `EnforceCodeStyleInBuild`.
- Generované soubory (migrace `*.Designer.cs`, `*ModelSnapshot.cs`, lock soubory). Skript je vynechává sám.
