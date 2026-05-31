# DOCS_ARCHITECT_PLUGIN_PLAN.md

**Status:** In Progress (implementace hotová, zbývá commit/PR)
**Vytvořeno:** 2026-05-30
**Vedoucí:** ladis (ladislav.filip@fullsys.cz)
**Ticket:** –
**Odhadovaný čas:** 1–2 hodiny

## Architektonický přehled

### Hlavní řešení

Zabalíme existující globální skill `docs-architect` (umístěný v `C:\Users\ladis\.claude\skills\docs-architect\`) do **nativního Claude Code pluginu** v tomto marketplace repu, do adresáře `plugins/docs-architect/`. Plugin distribuuje skill přes Git (žádné ZIP archivy), v souladu s konvencemi repozitáře a stávajících example pluginů.

Plugin bude obsahovat pouze **produkční obsah skillu** — `SKILL.md`, `references/` a `assets/`. Testovací artefakty (`evals/`) se **nekopírují**, protože jsou interní pro vývoj skillu a koncový uživatel je nepotřebuje.

### Separation of concerns

- **`plugins/docs-architect/.claude-plugin/plugin.json`** — manifest pluginu (jediné povinné pole `name`, musí odpovídat názvu adresáře).
- **`plugins/docs-architect/skills/docs-architect/`** — vlastní skill; složka `skills/` se v Claude Code skenuje automaticky, do `plugin.json` se neuvádí.
- **`plugins/docs-architect/README.md` + `CHANGELOG.md`** — dokumentace pluginu (rozcestník + historie změn).
- **`.claude-plugin/marketplace.json`** — index marketplace; přidá se třetí položka do pole `plugins[]`.

### Klíčová rozhodnutí

- **Název pluginu i skillu:** `docs-architect` (vyhovuje konvenci `^[a-z0-9-]+$`; `name` v `plugin.json` == název adresáře).
- **Verze:** `1.0.0` (striktní semver, konzistentní s example pluginy).
- **Soubor s plánem:** `DOCS_ARCHITECT_PLUGIN_PLAN.md` (stávající untracked `PLAN.md` zůstává nedotčen).
- **`evals/` se nedistribuuje** — pouze `SKILL.md`, `references/` (3 soubory), `assets/` (4 šablony).
- **Bez vlastních `commands/`, `agents/`, `.mcp.json`** — plugin nese jen skill.
- **Kódování UTF-8 + LF**, JSON odsazení 2 mezerami, bez trailing comma (vynucuje `.gitattributes`).
- **Žádné credentials ani PII** v žádném souboru pluginu.

> [!NOTE]
> Skill `docs-architect` ve frontmatteru nemá pole `version`. Manifest pluginu (`plugin.json`) tedy nese verzi pluginu (1.0.0); verzování skillu samotného řešit nemusíme. Pokud `plugin.json` verzi vynechá, Claude Code použije commit SHA — proto ji uvádíme explicitně.

## Fáze 1: Příprava a ověření zdroje ✅

**Cíl:** Ověřit, že zdrojový skill je kompletní a že cílová struktura repozitáře je připravená, abychom při kopírování nic neztratili ani nepřepsali.

**Kroky:**
1. Ověř obsah zdrojového adresáře `C:\Users\ladis\.claude\skills\docs-architect\` — musí obsahovat `SKILL.md`, `references/` (3× `.md`), `assets/` (4× `.md`), `evals/`.
2. Ověř, že cílový adresář `plugins/docs-architect/` v repu **zatím neexistuje** (žádná kolize).
3. Zkontroluj strukturu vzorového pluginu `plugins/example-hello-world/` jako referenci pro layout (`.claude-plugin/plugin.json`, `skills/<id>/SKILL.md`, `README.md`, `CHANGELOG.md`).
4. Přečti `.gitattributes`, abys potvrdil pravidla kódování (UTF-8, LF) pro nově vytvářené soubory.

**Ovlivněné soubory:**

*Nové:*
- (žádné — pouze ověřování)

*Upravované:*
- (žádné)

*Mazané:*
- (žádné)

**Kritéria dokončení:**
- [x] Zdrojový skill obsahuje `SKILL.md` + 3 soubory v `references/` + 4 soubory v `assets/`.
- [x] Adresář `plugins/docs-architect/` v repu neexistuje (žádná kolize).
- [x] Znám přesný layout dle `plugins/example-hello-world/`.
- [x] Znám pravidla kódování z `.gitattributes` (`* text=auto eol=lf`).

## Fáze 2: Zkopírování obsahu skillu do pluginu ✅

**Cíl:** Přenést produkční obsah skillu do struktury pluginu tak, aby relativní odkazy uvnitř `SKILL.md` (na `references/` a `assets/`) zůstaly funkční beze změny.

**Kroky:**
1. Vytvoř adresář `plugins/docs-architect/skills/docs-architect/`.
2. Zkopíruj `SKILL.md` ze zdroje do `plugins/docs-architect/skills/docs-architect/SKILL.md`.
3. Zkopíruj celou složku `references/` (3 soubory: `formatovani.md`, `struktura-repozitare.md`, `tone-of-voice.md`) do `plugins/docs-architect/skills/docs-architect/references/`.
4. Zkopíruj celou složku `assets/` (4 soubory: `dokument-template.md`, `README-template.md`, `CONTRIBUTING-template.md`, `CHANGELOG-template.md`) do `plugins/docs-architect/skills/docs-architect/assets/`.
5. **Nekopíruj** `evals/` (interní testy).
6. Ověř, že relativní odkazy v `SKILL.md` (`./references/...`, `./assets/...`) ukazují na existující soubory v nové lokaci.

**Ovlivněné soubory:**

*Nové:*
- `plugins/docs-architect/skills/docs-architect/SKILL.md`
- `plugins/docs-architect/skills/docs-architect/references/formatovani.md`
- `plugins/docs-architect/skills/docs-architect/references/struktura-repozitare.md`
- `plugins/docs-architect/skills/docs-architect/references/tone-of-voice.md`
- `plugins/docs-architect/skills/docs-architect/assets/dokument-template.md`
- `plugins/docs-architect/skills/docs-architect/assets/README-template.md`
- `plugins/docs-architect/skills/docs-architect/assets/CONTRIBUTING-template.md`
- `plugins/docs-architect/skills/docs-architect/assets/CHANGELOG-template.md`

*Upravované:*
- (žádné)

*Mazané:*
- (žádné)

**Kritéria dokončení:**
- [x] V `plugins/docs-architect/skills/docs-architect/` je `SKILL.md` + `references/` (3 soubory) + `assets/` (4 soubory).
- [x] Složka `evals/` zkopírovaná NENÍ.
- [x] `SKILL.md` má neporušený YAML frontmatter s poli `name: docs-architect` a `description`.
- [x] Všechny relativní odkazy v `SKILL.md` vedou na existující soubory.
- [x] Soubory jsou UTF-8 s LF konci řádků (zajistí `.gitattributes` při commitu).

## Fáze 3: Vytvoření manifestu a dokumentace pluginu ✅

**Cíl:** Doplnit povinný manifest `plugin.json` a dokumentaci (README jako rozcestník, CHANGELOG), aby byl plugin samonosný a odpovídal vzoru ostatních pluginů.

**Kroky:**
1. Vytvoř `plugins/docs-architect/.claude-plugin/plugin.json` se strukturou dle `example-hello-world` (pole: `name`, `description`, `version`, `author`, `license`, `keywords`).
   - `name`: `"docs-architect"` (musí odpovídat názvu adresáře).
   - `version`: `"1.0.0"`.
   - `keywords`: např. `["documentation", "docs", "readme", "markdown"]`.
   - **Neuváděj** `skills` (skenuje se automaticky) ani `mcpServers` (plugin nemá MCP).
2. Vytvoř `plugins/docs-architect/README.md` dle pravidel skillu `docs-architect` — H1 + meta-shrnutí (1–3 věty) + krátký rozcestník: co plugin obsahuje, jak ho nainstalovat (`/plugin`), co skill umí.
3. Vytvoř `plugins/docs-architect/CHANGELOG.md` ve formátu Keep a Changelog s položkou `## [1.0.0] - 2026-05-30` a sekcí `### Added` (první vydání: zabalení skillu docs-architect).
4. Zkontroluj, že JSON má odsazení 2 mezerami a žádnou trailing comma.

**Ovlivněné soubory:**

*Nové:*
- `plugins/docs-architect/.claude-plugin/plugin.json`
- `plugins/docs-architect/README.md`
- `plugins/docs-architect/CHANGELOG.md`

*Upravované:*
- (žádné)

*Mazané:*
- (žádné)

**Kritéria dokončení:**
- [x] `plugin.json` obsahuje povinné pole `name` == `"docs-architect"`.
- [x] `version` je validní semver `1.0.0`.
- [x] JSON je odsazený 2 mezerami, bez trailing comma, validní (ověřeno přes PowerShell ConvertFrom-Json).
- [x] `README.md` začíná `# H1` a má meta-shrnutí pod nadpisem.
- [x] `CHANGELOG.md` má položku `[1.0.0]` ve formátu Keep a Changelog.
- [x] Žádný soubor neobsahuje credentials ani PII.

## Fáze 4: Registrace pluginu do marketplace.json ✅

**Cíl:** Zaregistrovat plugin do indexu marketplace, aby byl objevitelný a instalovatelný přes `/plugin`.

**Kroky:**
1. Otevři `.claude-plugin/marketplace.json`.
2. Do pole `plugins[]` přidej třetí objekt (za `example-mcp`):
   - `"name": "docs-architect"`
   - `"source": "./plugins/docs-architect"`
   - `"description"`: stručný popis (1 věta) — tvorba a údržba technické dokumentace repozitáře (README, CONTRIBUTING, CHANGELOG, API docs, architektura).
3. Ověř, že název v `marketplace.json` odpovídá `name` v `plugin.json` i názvu adresáře.
4. Zkontroluj validitu JSON (2 mezery, bez trailing comma).

**Ovlivněné soubory:**

*Nové:*
- (žádné)

*Upravované:*
- `.claude-plugin/marketplace.json`

*Mazané:*
- (žádné)

**Kritéria dokončení:**
- [x] V `marketplace.json` je nová položka `docs-architect` s `source: "./plugins/docs-architect"`.
- [x] `name` v marketplace == `name` v `plugin.json` == název adresáře.
- [x] `marketplace.json` je validní JSON (ověřeno přes PowerShell ConvertFrom-Json).
- [x] Žádná z původních dvou položek (`example-hello-world`, `example-mcp`) nebyla porušena.

## Fáze 5: Validace a ověření ✅

**Cíl:** Ověřit, že celý marketplace i nový plugin splňují strukturální pravidla, aby PR prošel CI bez chyb.

**Kroky:**
1. Spusť validační skript `./scripts/validate-marketplace.sh` (na Windows přes Git Bash / WSL; vyžaduje `jq`).
2. Oprav případné nálezy validátoru (chybějící pole, nevalidní JSON, špatný název).
3. Vizuálně ověř strom pluginu — `plugins/docs-architect/` má `.claude-plugin/plugin.json`, `skills/docs-architect/SKILL.md`, `references/`, `assets/`, `README.md`, `CHANGELOG.md`.
4. (Volitelné) Lokálně přidej marketplace přes `/plugin marketplace add` a ověř, že se `docs-architect` nabízí k instalaci a skill se po instalaci aktivuje.
5. Připrav commit + PR na branch (CI workflow `.github/workflows/validate.yml` ověří strukturu automaticky).

**Ovlivněné soubory:**

*Nové:*
- (žádné)

*Upravované:*
- (žádné — pouze případné opravy z předchozích fází)

*Mazané:*
- (žádné)

**Kritéria dokončení:**
- [x] Kontroly validačního skriptu prošly (replikováno v PowerShellu – `jq` není lokálně dostupné; CI v Linuxu spustí `validate-marketplace.sh` přímo).
- [x] Strom pluginu odpovídá očekávané struktuře (manifest + skill + references + assets + README + CHANGELOG).
- [ ] (Volitelné) Plugin lze lokálně nainstalovat přes `/plugin` a skill `docs-architect` se aktivuje.
- [ ] Změny jsou připravené v commitu/PR; CI workflow `validate.yml` je zelené. *(zbývá – commit dělám až na pokyn)*

## Tracking tabulka

| Fáze | Status | Zahájeno | Dokončeno | Poznámky |
|------|--------|----------|-----------|----------|
| 1 | ✅ Hotovo | 2026-05-30 | 2026-05-30 | Zdroj kompletní (3 references + 4 assets), cíl bez kolize, LF dle .gitattributes |
| 2 | ✅ Hotovo | 2026-05-30 | 2026-05-30 | 8 souborů zkopírováno (SKILL.md + 3 references + 4 assets), evals/ vynecháno |
| 3 | ✅ Hotovo | 2026-05-30 | 2026-05-30 | plugin.json (validní JSON, v1.0.0) + README (rozcestník) + CHANGELOG |
| 4 | ✅ Hotovo | 2026-05-30 | 2026-05-30 | Přidána položka docs-architect, marketplace má 3 pluginy, JSON validní |
| 5 | ✅ Hotovo | 2026-05-30 | 2026-05-30 | Validace prošla (PS replika kontrol – jq není lokálně); strom OK; zbývá commit/PR |
