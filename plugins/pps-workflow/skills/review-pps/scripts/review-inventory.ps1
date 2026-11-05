#Requires -Version 7.0
# Inventura repa pro návrh REVIEW.md (skill `review-init-pps`). Posbírá fakta, ze kterých se kontrakt skládá:
# autority, pravidla, skilly, stack, kontroly v CI, rozbité odkazy a soubory, které mění skoro každý PR.
# Nic neposílá a v repu nic nemění - zapisuje jen inventory.md do dočasného adresáře.
#
#   pwsh -NoProfile -File review-inventory.ps1 -RepoPath ../planning
#
# Výstup na stdout: REPO=, HEAD=, BASE=, CONTRACT=, INVENTORY=, WARN=, při chybě ERROR= (exit 1).

[CmdletBinding()]
param(
    [string] $RepoPath = ".",
    # Base větev pro analýzu historie PR. Bez parametru origin/HEAD, jinak dev-sprint.
    [string] $Base = "",
    # Kolik posledních commitů base větve (first-parent = squash PR) projít.
    [int] $Commits = 20,
    [string] $OutDir = ""
)

$ErrorActionPreference = "Stop"
trap { Write-Output "ERROR=$($_.Exception.Message)"; exit 1 }
Import-Module (Join-Path $PSScriptRoot "ReviewCommon.psm1") -Force

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$warnings = New-Object System.Collections.Generic.List[string]
$md = New-Object System.Collections.Generic.List[string]

function Invoke-Git { & git -C $script:repoRoot @args }
function Test-Tracked([string] $Rel) {
    Invoke-Git ls-files --error-unmatch -- $Rel 2>$null > $null
    return $LASTEXITCODE -eq 0
}
function Get-LineCount([string] $Full) { return @([System.IO.File]::ReadAllLines($Full)).Count }
function Format-Short([string] $Text, [int] $Max = 140) {
    if (-not $Text) { return "" }
    $t = ($Text -replace '\s+', ' ').Trim().Replace("|", "\|")
    if ($t.Length -gt $Max) { return $t.Substring(0, $Max - 1) + "…" }
    return $t
}
function Get-Rel([string] $Full) { return [System.IO.Path]::GetRelativePath($script:repoRoot, $Full).Replace("\", "/") }

# --- repo a base ---------------------------------------------------------------------------------

$resolved = Resolve-Path -LiteralPath $RepoPath -ErrorAction SilentlyContinue
if (-not $resolved) { throw "Cesta '$RepoPath' neexistuje." }
$repoRoot = (& git -C $resolved.Path rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { throw "'$RepoPath' není git repozitář." }
$repoRoot = $repoRoot.Trim()
$repoName = Split-Path $repoRoot -Leaf

if (-not $Base) {
    $originHead = (Invoke-Git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null)
    $Base = if ($originHead) { $originHead.Trim() } else { "origin/dev-sprint" }
}
Invoke-Git rev-parse --verify --quiet "$Base^{commit}" > $null
if ($LASTEXITCODE -ne 0) { throw "Base '$Base' neexistuje." }
$baseBranch = $Base -replace '^origin/', ''

$head = (Invoke-Git rev-parse --short HEAD).Trim()
$branch = (Invoke-Git branch --show-current)
$remote = (Invoke-Git remote get-url origin 2>$null)
$contract = Join-Path $repoRoot "REVIEW.md"

if (-not $OutDir) { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) "pps-review-init-$repoName" }
if (Test-Path -LiteralPath $OutDir) {
    $isOurs = (Test-Path (Join-Path $OutDir "inventory.md")) -or @(Get-ChildItem -Force -LiteralPath $OutDir).Count -eq 0
    if (-not $isOurs) { throw "Adresář '$OutDir' není prázdný a nevypadá jako výstup inventury." }
}
else { New-Item -ItemType Directory -Force -Path $OutDir > $null }

$md.Add("# Inventura: $repoName")
$md.Add("")
$md.Add("| | |")
$md.Add("|---|---|")
$md.Add("| Cesta | ``$repoRoot`` |")
$md.Add("| Remote | ``$remote`` |")
$md.Add("| HEAD | ``$head`` ($branch) |")
$md.Add("| Base | ``$Base`` → do frontmatteru ``base: $baseBranch`` |")
$md.Add("| REVIEW.md | $(if (Test-Path $contract) { 'existuje – aktualizace, ne nový návrh' } else { 'neexistuje' }) |")
$md.Add("")

# --- autority ------------------------------------------------------------------------------------

$md.Add("## Autority")
$md.Add("")
$md.Add("| Soubor | Řádků | V gitu |")
$md.Add("|---|---|---|")
$authorityCandidates = @(
    "CLAUDE.md", "AGENTS.md", ".ai-rulez/context/AGENTS.md", ".ai-rulez/project-map.md", ".ai-rulez/registry.md", ".ai-rulez/config.yaml",
    "README.md", "CONTRIBUTING.md", ".github/copilot-instructions.md", ".editorconfig", "pull_request_template.md",
    "Directory.Build.props", "global.json"
)
$authorities = New-Object System.Collections.Generic.List[string]
foreach ($rel in $authorityCandidates) {
    $full = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $authorities.Add($rel)
    $md.Add("| ``$rel`` | $(Get-LineCount $full) | $(if (Test-Tracked $rel) { 'ano' } else { '**ne** (lokální / generované)' }) |")
}
foreach ($dir in @("docs/adr", "docs/decisions", "openspec/specs", "docs")) {
    $full = Join-Path $repoRoot $dir
    if (Test-Path -LiteralPath $full -PathType Container) {
        $n = @(Get-ChildItem -LiteralPath $full -Recurse -File -Filter *.md).Count
        $md.Add("| ``$dir/`` | $n souborů .md | $(if (Test-Tracked $dir) { 'ano' } else { 'ne' }) |")
    }
}
$md.Add("")

# --- pravidla ------------------------------------------------------------------------------------

$md.Add("## Pravidla")
$md.Add("")
$ruleRows = New-Object System.Collections.Generic.List[string]
foreach ($dir in @(".ai-rulez/rules", ".claude/rules")) {
    $full = Join-Path $repoRoot $dir
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($rule in (Get-ChildItem -LiteralPath $full -Filter *.md -File -Recurse | Sort-Object FullName)) {
        $rel = Get-Rel $rule.FullName
        $fm = Read-Frontmatter $rule.FullName
        $activation = if ($fm.ContainsKey("activation")) { $fm["activation"] } elseif ($fm.ContainsKey("apply")) { $fm["apply"] } else { "" }
        $globs = (Get-RuleGlobs $fm) -join ", "
        $ruleRows.Add("| ``$rel`` | $(if (Test-Tracked $rel) { 'ano' } else { 'ne' }) | $activation | $(Format-Short $globs 80) | $(Format-Short $fm['description']) |")
    }
}
if ($ruleRows.Count -eq 0) { $md.Add("Žádná. Pravidla s ``paths:`` repo nemá – mapu v ``REVIEW.md`` je nutné postavit ze skillů a autorit.") }
else {
    $md.Add("| Soubor | V gitu | activation | paths | description |")
    $md.Add("|---|---|---|---|---|")
    $ruleRows | ForEach-Object { $md.Add($_) }
}
$md.Add("")

# --- skilly --------------------------------------------------------------------------------------

$md.Add("## Skilly")
$md.Add("")
$skillRows = New-Object System.Collections.Generic.List[string]
foreach ($dir in @(".claude/skills", ".ai-rulez/skills", ".agents/skills")) {
    $full = Join-Path $repoRoot $dir
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($skill in (Get-ChildItem -LiteralPath $full -Filter SKILL.md -File -Recurse | Sort-Object FullName)) {
        $rel = Get-Rel $skill.FullName
        $fm = Read-Frontmatter $skill.FullName
        $invocable = if ($fm.ContainsKey("user-invocable")) { $fm["user-invocable"] } else { "" }
        $skillRows.Add("| ``$rel`` | $(if (Test-Tracked $rel) { 'ano' } else { 'ne' }) | $invocable | $(Format-Short $fm['description'] 180) |")
    }
}
# ai-rulez: centrální pravidla a skilly z `includes:` jsou jen ve vygenerovaném (gitignorovaném) výstupu.
$rulezConfig = Join-Path $repoRoot ".ai-rulez/config.yaml"
if (Test-Path $rulezConfig) {
    $sources = @([regex]::Matches([System.IO.File]::ReadAllText($rulezConfig), '(?m)^\s*source:\s*"?([^"\r\n]+)"?') | ForEach-Object { $_.Groups[1].Value.Trim() })
    if ($sources.Count -gt 0) {
        $generated = Test-Path (Join-Path $repoRoot ".agents/skills")
        $md.Add("ai-rulez načítá centrální obsah z: $(($sources | ForEach-Object { '`' + $_ + '`' }) -join ', '). " +
            $(if ($generated) { "Vygenerovaný výstup (``.agents/``) je k dispozici výš." }
              else { "Lokálně **není vygenerovaný** – plný text až po ``npx ai-rulez generate``. Skilly vyjmenovává ``.ai-rulez/registry.md``, pravidla jen blok ai-rulez v ``.gitignore``." }))
        $md.Add("")
        # Názvy vygenerovaných pravidel z bloku ai-rulez v .gitignore (jediné místo, kde jsou vidět bez generate).
        $gitignore = Join-Path $repoRoot ".gitignore"
        if (Test-Path $gitignore) {
            $inBlock = $false
            $ruleNames = New-Object System.Collections.Generic.SortedSet[string]
            foreach ($line in [System.IO.File]::ReadAllLines($gitignore)) {
                if ($line -match '^#\s*BEGIN ai-rulez') { $inBlock = $true; continue }
                if ($line -match '^#\s*END ai-rulez') { $inBlock = $false; continue }
                $m = [regex]::Match($line, 'rules/([^/]+?)\.(md|mdc)$')
                if ($inBlock -and $m.Success) { [void] $ruleNames.Add($m.Groups[1].Value) }
            }
            if ($ruleNames.Count -gt 0) {
                $md.Add("Centrální a vygenerovaná pravidla podle ``.gitignore`` (jen názvy, obsah lokálně není): " +
                    (($ruleNames | ForEach-Object { '`' + $_ + '`' }) -join ', '))
                $md.Add("")
            }
        }
        if (-not $generated) { $warnings.Add("Centrální pravidla a skilly ai-rulez nejsou lokálně vygenerované.") }
    }
}
if ($skillRows.Count -eq 0) { $md.Add("Žádné.") }
else {
    $md.Add("Skilly s ``user-invocable: false`` bývají znalostní (vzory, konvence) – kandidáti do mapy *Co číst podle změněné cesty*.")
    $md.Add("")
    $md.Add("| Soubor | V gitu | user-invocable | description |")
    $md.Add("|---|---|---|---|")
    $skillRows | ForEach-Object { $md.Add($_) }
}
$md.Add("")

# --- rozbité odkazy v autoritách -----------------------------------------------------------------

$md.Add("## Odkazy z autorit, které nevedou nikam")
$md.Add("")
$broken = New-Object System.Collections.Generic.List[string]
$generatedRefs = New-Object System.Collections.Generic.SortedSet[string]
foreach ($rel in $authorities) {
    if ($rel -notmatch '\.md$') { continue }
    $baseDir = Split-Path (Join-Path $repoRoot $rel) -Parent
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $repoRoot $rel))) {
        $lineNo++
        $targets = @()
        $targets += [regex]::Matches($line, '\]\(([^)\s]+)\)') | ForEach-Object { $_.Groups[1].Value }
        # Cesty v backticks, které vypadají jako soubor nebo složka repa.
        $targets += [regex]::Matches($line, '`((?:\.claude|\.ai-rulez|\.agents|\.github|src|tests|docs|scripts|openspec)/[^`\s*{}<>]+)`') | ForEach-Object { $_.Groups[1].Value }
        # Kořenové soubory buildu, které autority rády zmiňují (Directory.Packages.props, global.json, *.sln).
        $targets += [regex]::Matches($line, '`((?:Directory\.[\w.]+\.(?:props|targets)|global\.json|NuGet\.Config|[\w.-]+\.slnx?))`') | ForEach-Object { $_.Groups[1].Value }
        foreach ($t in $targets) {
            $t = [uri]::UnescapeDataString(($t -split '#')[0])
            # Zástupné cesty (`tests/…/Builders/`, `<repo>`) nejsou odkazy.
            if (-not $t -or $t -match '^[a-z]+:' -or $t.Contains("<") -or $t.Contains("…") -or $t.Contains("...")) { continue }
            $candidates = @((Join-Path $baseDir $t), (Join-Path $repoRoot $t))
            if ($candidates | Where-Object { Test-Path -LiteralPath $_ }) { continue }
            # Cíl v gitignorované cestě (např. vygenerované .agents/) vznikne až generováním - není rozbitý.
            Invoke-Git check-ignore -q --no-index -- $t 2>$null
            if ($LASTEXITCODE -eq 0) { $generatedRefs.Add($t); continue }
            $broken.Add("| ``$($rel):$lineNo`` | ``$t`` |")
        }
    }
}
if ($broken.Count -eq 0) { $md.Add("Žádné.") }
else {
    $md.Add("Rozbitý odkaz v autoritě je kandidát na rozpor autorita × kód – ověř a uveď ho uživateli, do ``REVIEW.md`` se nepíše.")
    $md.Add("")
    $md.Add("| Kde | Cíl |")
    $md.Add("|---|---|")
    $broken | Select-Object -Unique | ForEach-Object { $md.Add($_) }
}
$md.Add("")
if ($generatedRefs.Count -gt 0) {
    $md.Add("Odkazy do gitignorovaných (generovaných) cest – existují až po generování, z ``REVIEW.md`` na ně neodkazuj: " +
        (($generatedRefs | Select-Object -First 8 | ForEach-Object { '`' + $_ + '`' }) -join ', ') +
        $(if ($generatedRefs.Count -gt 8) { " a dalších $($generatedRefs.Count - 8)" } else { "" }))
    $md.Add("")
}

# --- stack ---------------------------------------------------------------------------------------

$md.Add("## Stack")
$md.Add("")
$projects = @(Invoke-Git ls-files -- '*.csproj' '*.fsproj')
$sln = @(Invoke-Git ls-files -- '*.sln' '*.slnx')
$frameworks = @{}
$packages = @{}
$interesting = @(
    "MongoDB.Driver", "Microsoft.EntityFrameworkCore", "Pomelo.EntityFrameworkCore.MySql", "Npgsql.EntityFrameworkCore.PostgreSQL",
    "MediatR", "FastEndpoints", "FluentValidation", "AutoMapper", "Mapster",
    "Fullsys.Brokers", "Fullsys.Pps", "Skoda.Pps",
    "xunit", "NUnit", "MSTest.TestFramework", "Moq", "NSubstitute", "FluentAssertions", "Shouldly", "AutoFixture",
    "Moq.EntityFrameworkCore", "Testcontainers", "NetArchTest.Rules", "TngTech.ArchUnitNET",
    "StyleCop.Analyzers", "SonarAnalyzer.CSharp", "Roslynator.Analyzers", "Meziantou.Analyzer"
)
# Vlastnosti buildu se čtou z projektů i z Directory.Build.props / Directory.Packages.props.
$buildFiles = @($projects) + @(Invoke-Git ls-files -- 'Directory.Build.props' '*/Directory.Build.props' 'Directory.Packages.props')
$buildText = ""
foreach ($p in $buildFiles) {
    $text = [System.IO.File]::ReadAllText((Join-Path $repoRoot $p))
    $buildText += "`n" + $text
    foreach ($m in [regex]::Matches($text, '<TargetFrameworks?>([^<]+)</TargetFrameworks?>')) {
        foreach ($f in $m.Groups[1].Value.Split(";")) { if ($f.Trim()) { $frameworks[$f.Trim()] = $true } }
    }
    foreach ($m in [regex]::Matches($text, '<Package(?:Reference|Version)\s+Include="([^"]+)"(?:\s+Version="([^"]+)")?')) {
        $name = $m.Groups[1].Value
        $hit = $interesting | Where-Object { $name -eq $_ -or $name.StartsWith("$_.") }
        if ($hit) { $packages[$name] = 1 + [int] $packages[$name] }
    }
}
$globalJson = Join-Path $repoRoot "global.json"
$sdk = if (Test-Path $globalJson) { ([regex]::Match([System.IO.File]::ReadAllText($globalJson), '"version"\s*:\s*"([^"]+)"')).Groups[1].Value } else { "" }
$warnAsErr = $buildText -match '<TreatWarningsAsErrors>\s*true'
$codeStyleInBuild = $buildText -match '<EnforceCodeStyleInBuild>\s*true'
$editorconfig = Join-Path $repoRoot ".editorconfig"
$silenced = if (Test-Path $editorconfig) {
    @([regex]::Matches([System.IO.File]::ReadAllText($editorconfig), '(?m)^\s*dotnet_diagnostic\.(\w+)\.severity\s*=\s*(none|silent)') | ForEach-Object { $_.Groups[1].Value })
} else { @() }
$md.Add("| | |")
$md.Add("|---|---|")
$slnText = ($sln | ForEach-Object { '`' + $_ + '`' }) -join ', '
$md.Add("| Solution | $slnText |")
$md.Add("| Projektů | $($projects.Count) |")
$md.Add("| TargetFramework | $(($frameworks.Keys | Sort-Object) -join ', ') |")
$md.Add("| SDK (global.json) | $sdk |")
$md.Add("| TreatWarningsAsErrors | $(if ($warnAsErr) { 'ano' } else { 'ne / nezjištěno' }) |")
$md.Add("| EnforceCodeStyleInBuild | $(if ($codeStyleInBuild) { 'ano' } else { '**ne** – pravidla stylu (`IDE*`) z `.editorconfig` build nehlídá' }) |")
$md.Add("| Diagnostiky vypnuté v .editorconfig | $(if ($silenced.Count -gt 0) { Format-Short (($silenced | Select-Object -Unique) -join ', ') 200 } else { 'žádné' }) |")
$md.Add("")
$md.Add("Do *Neřeš* patří jen to, co build nebo Sonar **skutečně** hlídá: bez ``EnforceCodeStyleInBuild`` styl z ``.editorconfig`` nehlídá nikdo kromě IDE.")
$md.Add("")
$pkgText = (($packages.GetEnumerator() | Sort-Object Name) | ForEach-Object { '`' + $_.Name + '` (' + $_.Value + ')' }) -join ", "
$md.Add("Balíčky (počet projektů): " + $pkgText)
$md.Add("")
$files = @(Invoke-Git ls-files -- '*.cs' '*.ts' '*.py' '*.go' '*.java')
$md.Add("Zdrojových souborů v gitu: $($files.Count) (z toho v ``tests/``: $(@($files | Where-Object { $_ -like 'tests/*' -or $_ -like '*Tests/*' -or $_ -like '*.Tests/*' }).Count))")
$md.Add("")

# --- kontroly v CI -------------------------------------------------------------------------------

$md.Add("## Kontroly v CI")
$md.Add("")
$pipelines = @(Invoke-Git ls-files -- '*.yml' '*.yaml' | Where-Object { $_ -match '(?i)(pipeline|azure-pipelines|\.github/workflows)' })
if ($pipelines.Count -eq 0) { $md.Add("Žádná pipeline v repu.") }
else {
    $md.Add("Jen textová stopa v souboru. Šablony (``template:``) se nečtou, takže prázdná buňka neznamená, že se kontrola nespouští.")
    $md.Add("")
    $md.Add("| Pipeline | Sonar | ``test`` v souboru | Xray | Šablony |")
    $md.Add("|---|---|---|---|---|")
    foreach ($p in $pipelines) {
        $t = [System.IO.File]::ReadAllText((Join-Path $repoRoot $p))
        $templates = @([regex]::Matches($t, '(?m)template:\s*([^\s#]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        $md.Add("| ``$p`` | $(if ($t -match '(?i)sonar') { 'ano' } else { '' }) | $(if ($t -match '(?i)dotnet test|\btest\b') { 'ano' } else { '' }) | $(if ($t -match '(?i)xray') { 'ano' } else { '' }) | $(Format-Short ($templates -join ', ') 120) |")
    }
    $md.Add("")
    $md.Add("Co hlásí Sonar nebo build, patří do *Neřeš*. Detail nastavení Sonaru (quality gate) z repa nevyčteš – nehádej.")
}
$md.Add("")

# --- historie PR ---------------------------------------------------------------------------------

$md.Add("## Posledních $Commits commitů ``$Base`` (first-parent)")
$md.Add("")
$log = @(Invoke-Git log $Base --first-parent -n $Commits --format='%h%x09%ad%x09%s' --date=short)
$freq = @{}
$rows = New-Object System.Collections.Generic.List[string]
foreach ($entry in $log) {
    $parts = $entry.Split("`t", 3)
    $changed = @(Invoke-Git diff --name-only "$($parts[0])^" $parts[0] 2>$null)
    foreach ($f in $changed) { $freq[$f] = 1 + [int] $freq[$f] }
    # Kód = vše kromě dokumentace a archivu OpenSpec; na kalibraci záleží hlavně na něm.
    $code = @($changed | Where-Object { $_ -notmatch '\.md$' -and $_ -notmatch '^openspec/changes/archive/' })
    $rows.Add("| ``$($parts[0])`` | $($parts[1]) | $($changed.Count) | $($code.Count) | $(Format-Short $parts[2] 90) |")
}
$threshold = [math]::Ceiling($log.Count * 0.6)
$noisy = @($freq.GetEnumerator() | Where-Object { $_.Value -ge $threshold -and $log.Count -ge 5 } | Sort-Object Value -Descending)
$noisyText = if ($noisy.Count -gt 0) {
    ($noisy | ForEach-Object { '`' + $_.Name + '` (' + $_.Value + '/' + $log.Count + ')' }) -join ", "
} else { "žádné" }
$md.Add("**Soubory měněné v ≥ 60 % commitů** (kandidáti do *Neřeš*, např. zvýšení verze): " + $noisyText)
$md.Add("")
$md.Add("Commity vhodné na zkušební review (3–12 souborů kódu) vyber z tabulky. Číslo PR je v popisu commitu (``Merged PR <číslo>``).")
$md.Add("")
$md.Add("| Commit | Datum | Souborů | Z toho kód | Popis |")
$md.Add("|---|---|---|---|---|")
$rows | ForEach-Object { $md.Add($_) }

$inventory = Join-Path $OutDir "inventory.md"
[System.IO.File]::WriteAllText($inventory, ($md -join "`n") + "`n", $utf8NoBom)

if ($broken.Count -gt 0) { $warnings.Add("Autority obsahují $(@($broken | Select-Object -Unique).Count) odkazů, které nevedou nikam.") }
if (-not ($authorities | Where-Object { $_ -in @("CLAUDE.md", "AGENTS.md", ".ai-rulez/context/AGENTS.md") })) {
    $warnings.Add("Repo nemá CLAUDE.md ani AGENTS.md – kontrakt se bude opírat jen o kód.")
}

Write-Output "REPO=$repoRoot"
Write-Output "HEAD=$head"
Write-Output "BASE=$Base"
Write-Output "CONTRACT=$(if (Test-Path $contract) { $contract } else { 'none' })"
Write-Output "INVENTORY=$inventory"
foreach ($w in $warnings) { Write-Output "WARN=$w" }
