# CI/CD — Azure DevOps pipeline pro `.http` testy (httpyac)

Šablona YAML pipeline, která spustí `.http` testy přes **httpyac CLI** a publikuje výsledky
jako JUnit. Vzor:

1. `NodeTool@0` — Node.js (httpyac je npm balíček).
2. `npm install -g httpyac` — httpyac CLI (lze připnout verzi, viz níže).
3. `httpyac send … --junit > junit-report.xml` — spuštění testů, JUnit na stdout do souboru.
4. `PublishTestResults@2` — publikace JUnit; `failTaskOnFailedTests: true` zčervená build.

## Klíčové principy

- **Secrety přes variable group / secret proměnnou**, nikdy v repu. Secret proměnná se do
  httpyac dostane jen tak, že ji explicitně namapuješ do `env:` kroku (secret proměnné se
  jinak do prostředí procesu **nepropagují**). httpyac ji přečte přes `{{$processEnv API_TOKEN}}`.
- **Publikace výsledků musí běžet i při selhání testů** → `condition: succeededOrFailed()` na
  publish kroku a `continueOnError: true` na kroku s httpyac (jinak `--bail` shodí job dřív, než
  se výsledky publikují). Červený build zajistí `failTaskOnFailedTests: true`.
- **Environment** vybírej proměnnou (`$(httpEnv)`) — snadné přepínání local/staging/prod podle
  větve nebo parametru pipeline.

## Šablona: `azure-pipelines-http-tests.yml`

```yaml
# HTTP/API testy (.http přes httpyac) — Azure DevOps
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - http/**            # spouštěj jen při změně testů/kódu API dle potřeby

pool:
  vmImage: ubuntu-latest

variables:
  - group: http-tests-secrets   # variable group se secret proměnnou API_TOKEN
  - name: httpEnv
    value: staging              # cílový environment z http-client.env.json
  - name: httpGlob
    value: 'http/**/*.http'
  - name: httpyacVersion
    value: '6.16.7'             # připnutá verze pro reprodukovatelnost

steps:
  - task: NodeTool@0
    displayName: 'Instaluj Node.js'
    inputs:
      versionSpec: '20.x'

  - script: npm install -g httpyac@$(httpyacVersion)
    displayName: 'Instaluj httpyac CLI'

  - script: httpyac send "$(httpGlob)" --all -e $(httpEnv) --bail --junit > junit-report.xml
    displayName: 'Spusť .http testy (httpyac)'
    continueOnError: true         # ať se výsledky stihnou publikovat i po selhání
    env:
      # Secret proměnná z variable group se MUSÍ explicitně namapovat do env procesu.
      API_TOKEN: $(API_TOKEN)

  - task: PublishTestResults@2
    displayName: 'Publikuj výsledky (JUnit)'
    condition: succeededOrFailed()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'junit-report.xml'
      testRunTitle: 'HTTP API testy ($(httpEnv))'
      failTaskOnFailedTests: true   # červený build, když nějaký test selže
```

## Variable group / secrets

1. **Pipelines → Library → Variable groups** → nová skupina, např. `http-tests-secrets`.
2. Přidej proměnnou `API_TOKEN`, hodnotu vyplň a klikni na **zámeček** (secret). Secret
   hodnoty se nikdy nevypisují do logu.
3. V YAML ji zpřístupni přes `variables: - group: http-tests-secrets` a **explicitně namapuj**
   do `env:` kroku s httpyac (`API_TOKEN: $(API_TOKEN)`) — bez toho ji proces httpyac neuvidí.

> Alternativně Azure Key Vault propojený s variable group; princip mapování do `env:` je stejný.

## Přepínání environmentu podle větve (volitelné)

Místo pevného `value: staging` lze environment odvodit z větve:

```yaml
variables:
  - group: http-tests-secrets
  - name: httpEnv
    ${{ if eq(variables['Build.SourceBranchName'], 'main') }}:
      value: prod
    ${{ else }}:
      value: staging
```

`prod` běh proti ostrému prostředí zvaž spouštět jen ručně / na tag, ne na každý push.

## Časté problémy

| Problém | Příčina | Řešení |
|---------|---------|--------|
| Test results se nepublikují po selhání | `--bail` shodí job před publish krokem | `continueOnError: true` na httpyac kroku + `condition: succeededOrFailed()` na publish |
| `API_TOKEN` je prázdný | secret proměnná se nepropaguje automaticky | namapuj ji do `env:` kroku (`API_TOKEN: $(API_TOKEN)`) |
| JUnit XML je „znečištěné" logem | do stdout tekl i výpis odpovědí | přidej `-o none` do httpyac příkazu |
| Build je zelený i s failed testy | chybí `failTaskOnFailedTests` | nastav `failTaskOnFailedTests: true` v `PublishTestResults@2` |

## Poznámka pro Fullsys prostředí

Pro odchozí volání na interní systémy (FIS, BILLING 2.0, NEXT WMS) používej v `http-client.env.json`
proměnné a interní URL nastav přes variable group / self-hosted agenta se síťovým přístupem —
do repa nedávej produkční URL s citlivým významem ani produkční tokeny.
