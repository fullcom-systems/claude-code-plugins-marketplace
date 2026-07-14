# CI/CD — GitHub Actions workflow pro `.http` testy (httpyac)

Šablona workflow, která spustí `.http` testy přes **httpyac CLI** a publikuje výsledky jako
JUnit. Vzor:

1. `actions/setup-node` — Node.js (httpyac je npm balíček).
2. `npm install -g httpyac` — httpyac CLI (lze připnout verzi).
3. `httpyac send … --junit > junit-report.xml` — spuštění testů, JUnit na stdout do souboru.
4. Publikace výsledků — **`dorny/test-reporter`** (hezký report + status kontroly), s fallbackem
   na upload JUnit jako **artifact** přes `actions/upload-artifact`.

## Klíčové principy

- **Secrety přes GitHub Actions secrets** (`Settings → Secrets and variables → Actions`), nikdy
  v repu. Do httpyac se dostanou přes `env: API_TOKEN: ${{ secrets.API_TOKEN }}`; httpyac je
  přečte jako `{{$processEnv API_TOKEN}}`.
- **Publikace výsledků musí běžet i při selhání testů** → `if: always()` na reporting kroku a
  `continue-on-error: true` na kroku s httpyac (jinak `--bail` ukončí job dřív, než se výsledky
  zveřejní). Červený status zajistí `dorny/test-reporter` (`fail-on-error: true`, default) nebo
  explicitní `exit 1` podle uloženého outcome.
- `dorny/test-reporter` potřebuje oprávnění `checks: write` (a `pull-requests: write` pro
  komentář v PR).

## Šablona: `.github/workflows/http-tests.yml`

```yaml
name: HTTP API testy

on:
  push:
    branches: [ main, develop ]
    paths: [ 'http/**' ]
  pull_request:
    paths: [ 'http/**' ]

permissions:
  contents: read
  checks: write          # dorny/test-reporter zapisuje check run
  pull-requests: write   # a komentář do PR (volitelné)

jobs:
  http-tests:
    runs-on: ubuntu-latest
    env:
      HTTP_ENV: staging               # cílový environment z http-client.env.json
      HTTP_GLOB: 'http/**/*.http'
      HTTPYAC_VERSION: '6.16.7'       # připnutá verze
    steps:
      - uses: actions/checkout@v4

      - name: Nastav Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Instaluj httpyac CLI
        run: npm install -g httpyac@$HTTPYAC_VERSION

      - name: Spusť .http testy (httpyac)
        id: httpyac
        continue-on-error: true       # ať se výsledky stihnou publikovat i po selhání
        env:
          API_TOKEN: ${{ secrets.API_TOKEN }}
        run: httpyac send "$HTTP_GLOB" --all -e "$HTTP_ENV" --bail --junit > junit-report.xml

      - name: Publikuj výsledky (JUnit)
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: HTTP API testy (${{ env.HTTP_ENV }})
          path: junit-report.xml
          reporter: java-junit         # JUnit XML reporter
          fail-on-error: true          # červený check, když nějaký test selže

      - name: Ulož JUnit report jako artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: junit-report
          path: junit-report.xml
```

## Secrets

1. **Settings → Secrets and variables → Actions → New repository secret**.
2. Vytvoř secret `API_TOKEN` (pro víc prostředí zvaž **Environments** s vlastními secrety a
   ochranou schválením pro `prod`).
3. V kroku s httpyac ho zpřístupni přes `env: API_TOKEN: ${{ secrets.API_TOKEN }}`; httpyac ho
   čte jako `{{$processEnv API_TOKEN}}` z `http-client.env.json`.

## Varianta bez test-reporteru (jen artifact)

Pokud nechceš přidávat `dorny/test-reporter` (např. kvůli oprávněním na forku), vynech reporting
krok a nech jen upload artifactu — a build ať selže přímo podle výsledku httpyac:

```yaml
      - name: Spusť .http testy (httpyac)
        env:
          API_TOKEN: ${{ secrets.API_TOKEN }}
        run: httpyac send "$HTTP_GLOB" --all -e "$HTTP_ENV" --bail --junit > junit-report.xml
        # bez continue-on-error → nenulový exit z httpyac shodí job (červený build)

      - name: Ulož JUnit report jako artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: junit-report
          path: junit-report.xml
```

## Přepínání environmentu podle větve (volitelné)

```yaml
    steps:
      - name: Urči environment
        id: env
        run: |
          if [ "${{ github.ref_name }}" = "main" ]; then
            echo "value=prod" >> "$GITHUB_OUTPUT"
          else
            echo "value=staging" >> "$GITHUB_OUTPUT"
          fi
      # dále používej -e "${{ steps.env.outputs.value }}"
```

`prod` běh proti ostrému prostředí zvaž spouštět jen ručně (`workflow_dispatch`) nebo na tag.

## Časté problémy

| Problém | Příčina | Řešení |
|---------|---------|--------|
| Report se neobjeví po selhání | `--bail` ukončí job před reporting krokem | `continue-on-error: true` na httpyac kroku + `if: always()` na reportingu |
| `dorny/test-reporter` selže na oprávnění | chybí `permissions: checks: write` | doplň blok `permissions:` (viz šablona) |
| `API_TOKEN` je prázdný | secret není namapován do `env:` | přidej `env: API_TOKEN: ${{ secrets.API_TOKEN }}` ke kroku |
| JUnit XML je „znečištěné" logem | do stdout tekl i výpis odpovědí | přidej `-o none` do httpyac příkazu |

## Poznámka pro Fullsys prostředí

Pro odchozí volání na interní systémy (FIS, BILLING 2.0, NEXT WMS) používej v `http-client.env.json`
proměnné a interní URL/secrety řeš přes GitHub Actions secrets nebo self-hosted runner se síťovým
přístupem — do repa nedávej produkční URL s citlivým významem ani produkční tokeny.
