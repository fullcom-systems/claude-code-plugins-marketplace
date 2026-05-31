# Závazná struktura dokumentace v repozitáři

Meta-shrnutí: Referenční pravidla pro to, kde má v repozitáři jaký dokument žít a jak fungují rozcestníky mezi složkami. Cílová skupina: Claude při zařazování a tvorbě dokumentace.

## Obsah

- [Adresářová struktura](#adresářová-struktura)
- [Význam jednotlivých složek](#význam-jednotlivých-složek)
- [Princip rozcestníků](#princip-rozcestníků)
- [Pojmenování souborů](#pojmenování-souborů)

## Adresářová struktura

Veškerý dokumentační obsah musí striktně dodržovat tuto strukturu:

```text
moje-aplikace/
├── README.md                 # 1. Úvodní popis (hlavní vstupní brána a globální rozcestník)
├── CHANGELOG.md              # 6. Historie změn (formát Keep a Changelog)
├── CONTRIBUTING.md           # 2. Onboarding pro vývojáře (zprovoznění, git flow)
├── docs/                     # Hlavní složka pro veškerou detailní dokumentaci
│   ├── development/          # 5. Vývojářská dokumentace (architektura, API, byznys logika)
│   ├── devops/               # 3. DevOps a CI/CD (nasazení, pipelines, infrastruktura)
│   ├── support/              # 4. Netechnická podpora (FAQ, troubleshooting, admin guide)
│   └── misc/                 # 7. Nezařaditelná a ostatní dokumentace
└── ... (zdrojové kódy)
```

> [!IMPORTANT]
> Tato struktura je závazná. Nevytvářej alternativní složky (`documentation/`, `wiki/`, `help/`) – dokumentace patří do `docs/` a jejích čtyř podsložek. Když obsah nikam nesedí, jde do `docs/misc/`, ne do nově vymyšlené složky.

## Význam jednotlivých složek

| Složka | Cílová skupina | Typický obsah | Tón |
|---|---|---|---|
| `README.md` (kořen) | Všichni | Co projekt dělá, jak začít, globální rozcestník | Stručný, zvoucí |
| `CONTRIBUTING.md` (kořen) | Vývojář (nový) | Zprovoznění lokálně, git flow, konvence, jak přispět | Technický, návodný |
| `CHANGELOG.md` (kořen) | Všichni | Historie verzí dle [Keep a Changelog](https://keepachangelog.com/cs/) | Stručný, faktický |
| `docs/development/` | Vývojář | Architektura, API specifikace, datový model, byznys logika | Úderný, technický, hodně kódu |
| `docs/devops/` | DevOps | Nasazení, CI/CD pipelines, infrastruktura, monitoring | Úderný, přesné příkazy |
| `docs/support/` | Netechnická podpora | FAQ, troubleshooting, admin guide, postupy krok za krokem | Polopatický, bez žargonu |
| `docs/misc/` | Různá | Cokoli, co nepatří jinam | Dle obsahu |

> [!NOTE]
> `docs/development/` je **záměrně izolovaná od AI/agentích instrukcí**. Drž tam čistou technickou dokumentaci pro lidi-vývojáře (architektura, API, byznys logika). Prompty, instrukce pro Claude a podobné AI-specifické artefakty sem nepatří – mají vlastní místo mimo tuto strukturu (např. `.claude/`, `skills/`).

## Princip rozcestníků

Rozcestník (routing) je vstupní bod složky, který čtenáře a AI nástroje navede k detailům. Funguje na dvou úrovních.

**Globální rozcestník – kořenový `README.md`.** Krátce řekne, co projekt je, jak ho rozjet, a pak nasměruje do sekcí. Obsahuje relativní odkazy na hlavní oblasti:

```markdown
## Dokumentace

- [Pro vývojáře](./docs/development/README.md) – architektura, API, byznys logika
- [DevOps a nasazení](./docs/devops/README.md) – pipelines, infrastruktura
- [Pro podporu](./docs/support/README.md) – FAQ, troubleshooting, admin guide
- [Jak přispět](./CONTRIBUTING.md) – zprovoznění a git flow
- [Historie změn](./CHANGELOG.md)
```

**Lokální rozcestník – `README.md` uvnitř každé `docs/` podsložky.** Krátké meta-shrnutí sekce a pak odkazy na jednotlivé soubory uvnitř:

```markdown
# Vývojářská dokumentace

Meta-shrnutí: Technická dokumentace BILLING 2.0 pro vývojáře – architektura, API a byznys logika. Cílová skupina: vývojáři a integrátoři.

## Obsah sekce

- [Přehled architektury](./architektura.md)
- [API specifikace](./api-specs.md)
- [Datový model](./datovy-model.md)
```

> [!TIP]
> Pravidlo dvou kliků: z kořenového README se má čtenář dostat k jakémukoli dokumentu nejvýše přes jeden mezilehlý rozcestník. Když to nejde, sekce je moc plochá nebo moc hluboká – přeskupit.

## Pojmenování souborů

- Soubory v `docs/` pojmenovávej malými písmeny, slova spojuj pomlčkou, bez diakritiky v názvu souboru: `api-specs.md`, `datovy-model.md`, `nasazeni-produkce.md`.
- Vstupní rozcestník složky se vždy jmenuje `README.md` (GitHub ho renderuje automaticky při otevření složky).
- Kořenové soubory `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md` velkými písmeny dle konvence.
