#Requires -Version 7.0
# Připraví vstup pro lokální code review mikroslužby PPS G2 podle kontraktu v1:
#   - rozdělí diff proti base větvi na patche per soubor a očísluje řádky v hunku,
#   - najde kontrakt repa (REVIEW.md) a přečte jeho frontmatter,
#   - vybere pravidla (.claude/rules, .ai-rulez/rules, mapa z REVIEW.md), která se změny týkají.
# Nic neposílá, nic nepublikuje a v repu nic nemění - zapisuje jen do dočasného adresáře.
#
# Spouští ho skill `review-pps`. Ručně dává smysl jen na ladění:
#   pwsh -NoProfile -File review-diff.ps1 -RepoPath ../planning
#   pwsh -NoProfile -File review-diff.ps1 -RepoPath . -Base origin/dev-sprint -IncludeWorkingTree
#
# Výstup: řádky KLÍČ=hodnota na stdout (CONTRACT, CONTRACT_VERSION, BASE, DIFF_DIR, INDEX, RULES,
# SKIPPED, CRITERIA_CHANGED, WARN). Význam drží kontrakt, §8.
#
# Vychází ze scripts/review-local.ps1 projektu Billing (anotace řádků, globy). Rozdíly: kontrakt
# z REVIEW.md, výchozí base dev-sprint, pravidla i z .ai-rulez/rules, mapa cest z REVIEW.md, vynechané soubory.

[CmdletBinding()]
param(
    # Repo, které se posuzuje. Výchozí je aktuální adresář; skill spouštěný z kořene PPS předá cestu.
    [string] $RepoPath = ".",

    # Větev nebo commit, proti kterému se porovnává (three-dot, jako u PR). Bez parametru se vezme
    # `base` z REVIEW.md, jinak `dev-sprint`.
    [string] $Base = "",

    # Kam zapsat vstup review. Obsah se před každým během maže (jen pokud vypadá jako výstup review).
    [string] $OutDir = "",

    # Posuzovat i necommitnuté změny.
    [switch] $IncludeWorkingTree,

    # Kontrakt mimo kořen repa: návrh REVIEW.md v pilotu, nebo kritéria z jiného checkoutu
    # (review cizího PR v dočasném worktree). Relativní odkazy z něj se řeší vůči kořeni repa.
    [string] $ContractPath = ""
)

$ErrorActionPreference = "Stop"
# Výstup čte model, ne terminál: chyba jako jeden řádek ERROR=… bez barev a výpisu zásobníku.
trap { Write-Output "ERROR=$($_.Exception.Message)"; exit 1 }
Import-Module (Join-Path $PSScriptRoot "ReviewCommon.psm1") -Force
$ContractVersionSupported = 1
$ContractMaxLines = 200
$DefaultBase = "dev-sprint"

# Generované a strojové soubory, které review nečte nikdy. REVIEW.md může přidat další (`vynechat:`).
$DefaultSkip = @(
    "**/packages.lock.json",
    "**/package-lock.json",
    "**/yarn.lock",
    "**/pnpm-lock.yaml",
    "**/Migrations/*.Designer.cs",
    "**/Migrations/*ModelSnapshot.cs"
)

# Změna těchto cest mění kritéria review - skill to musí říct nahlas. Skilly a další dokumenty sem patří jen tehdy,
# když na ně odkazuje REVIEW.md (sekce Autority nebo mapa cest) - pracovní skilly (commit, pr) kritérii nejsou.
$CriteriaGlobs = @(
    "REVIEW.md",
    "CLAUDE.md",
    "AGENTS.md",
    ".claude/rules/**",
    ".ai-rulez/context/**",
    ".ai-rulez/rules/**",
    ".ai-rulez/project-map.md"
)
# Autority repa bez REVIEW.md (fallback skillu).
$FallbackAuthorities = @("CLAUDE.md", ".ai-rulez/context/AGENTS.md", "AGENTS.md", ".github/copilot-instructions.md")

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Warning([string] $Text) { $warnings.Add($Text) }

function Write-TextFile {
    param([string] $Path, [string[]] $Lines)
    $text = if ($Lines.Count -gt 0) { ($Lines -join "`n") + "`n" } else { "" }
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}

function Invoke-Git {
    # Git vždy nad posuzovaným repem, bez ohledu na aktuální adresář procesu.
    & git -C $script:repoRoot @args
}

# --- anotace a dělení diffu (převzato z Billingu beze změny chování) -------------------------

function Get-HunkStarts {
    param([string] $Header)
    $m = [regex]::Match($Header, '^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@')
    if (-not $m.Success) { return $null }
    return @([int] $m.Groups[1].Value, [int] $m.Groups[2].Value)
}

function ConvertTo-AnnotatedPatch {
    <# Každý řádek hunku dostane prefix `<starý> <nový>| `, aby odkazy v nálezech seděly. #>
    param([string[]] $Lines)

    $out = New-Object System.Collections.Generic.List[string]
    $inHunk = $false
    $old = 0
    $new = 0

    foreach ($line in $Lines) {
        if ($line -like "diff --git *") { $inHunk = $false; $out.Add($line); continue }
        if ($line -like "@@*") {
            $starts = Get-HunkStarts $line
            if ($null -ne $starts) { $old = $starts[0]; $new = $starts[1]; $inHunk = $true }
            $out.Add($line)
            continue
        }
        if (-not $inHunk) { $out.Add($line); continue }

        if ($line.StartsWith("+")) {
            $out.Add(("{0,5} {1,5}| {2}" -f "", $new, $line)); $new++
        }
        elseif ($line.StartsWith("-")) {
            $out.Add(("{0,5} {1,5}| {2}" -f $old, "", $line)); $old++
        }
        elseif ($line.StartsWith(" ") -or $line -eq "") {
            # Prázdný kontextový řádek (ořezaná mezera) musí posunout obě počítadla.
            $out.Add(("{0,5} {1,5}| {2}" -f $old, $new, $line)); $old++; $new++
        }
        else {
            $out.Add($line)   # "\ No newline at end of file"
        }
    }
    return $out.ToArray()
}

function Split-Diff {
    <#
        Rozdělí diff na položky per soubor. Cesta se bere z hlavičky patche (`+++ b/`, u smazaných
        `--- a/`, u přejmenování `rename to`), ne z řádku `diff --git` - ten se u cest s mezerou
        nedá spolehlivě rozdělit.
    #>
    param([string[]] $Lines)

    $items = New-Object System.Collections.Generic.List[psobject]
    $current = $null

    foreach ($line in $Lines) {
        if ($line -like "diff --git *") {
            $guess = ($line -replace '^diff --git a/', '') -replace ' b/[^ ]*$', ''
            $current = [pscustomobject]@{
                Path = ""; Guess = $guess; Added = 0; Deleted = 0; InHdr = $true
                Lines = (New-Object System.Collections.Generic.List[string])
            }
            $items.Add($current)
        }
        if ($null -eq $current) { continue }

        $current.Lines.Add($line)
        if ($current.InHdr -and $line -like "@@*") { $current.InHdr = $false; continue }

        if ($current.InHdr) {
            if ($line -like "+++ *" -and $line -ne "+++ /dev/null") {
                $current.Path = ($line -replace '^\+\+\+ b/', '').TrimEnd("`t")
            }
            elseif ($line -like "--- *" -and $line -ne "--- /dev/null" -and $current.Path -eq "") {
                $current.Path = ($line -replace '^--- a/', '').TrimEnd("`t")
            }
            elseif ($line -like "rename to *") {
                $current.Path = ($line -replace '^rename to ', '').TrimEnd("`t")
            }
            continue
        }

        if ($line.StartsWith("+")) { $current.Added++ }
        elseif ($line.StartsWith("-")) { $current.Deleted++ }
    }

    foreach ($item in $items) { if ($item.Path -eq "") { $item.Path = $item.Guess } }
    return $items.ToArray()
}


# --- REVIEW.md: mapa cest a odkazy -------------------------------------------------------------

function Get-ContractMap {
    <#
        Tabulka v sekci `## Co číst podle změněné cesty`: 1. sloupec zdroj (odkaz nebo `cesta`),
        2. sloupec globy v backticks. Vrací položky @{ Source; Globs }.
    #>
    param([string[]] $Lines)

    $map = New-Object System.Collections.Generic.List[psobject]
    $inSection = $false
    foreach ($line in $Lines) {
        if ($line -match '^##\s') { $inSection = $line -match '^##\s+Co číst podle změněné cesty'; continue }
        if (-not $inSection -or -not $line.TrimStart().StartsWith("|")) { continue }

        $cells = $line.Trim().Trim("|").Split("|")
        if ($cells.Count -lt 2) { continue }
        if ($cells[0] -match '^\s*:?-{3,}') { continue }   # oddělovač hlavičky

        $src = [regex]::Match($cells[0], '\]\(([^)#\s]+)')
        $source = if ($src.Success) { $src.Groups[1].Value } else {
            $tick = [regex]::Match($cells[0], '`([^`]+)`'); if ($tick.Success) { $tick.Groups[1].Value } else { "" }
        }
        $globs = @([regex]::Matches($cells[1], '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value })
        if ($source -and $globs.Count -gt 0) {
            $map.Add([pscustomobject]@{ Source = $source; Globs = $globs })
        }
    }
    return $map.ToArray()
}

function Get-ContractAuthorities {
    <# Relativní odkazy ze sekce `## Autority` v REVIEW.md. #>
    param([string[]] $Lines)
    $result = New-Object System.Collections.Generic.List[string]
    $inSection = $false
    foreach ($line in $Lines) {
        if ($line -match '^##\s') { $inSection = $line -match '^##\s+Autority\s*$'; continue }
        if (-not $inSection) { continue }
        foreach ($m in [regex]::Matches($line, '\]\(([^)\s#]+)')) {
            $t = [uri]::UnescapeDataString($m.Groups[1].Value)
            if ($t -notmatch '^[a-z]+:' -and -not $result.Contains($t)) { $result.Add($t) }
        }
    }
    return $result.ToArray()
}

function Test-ContractLinks {
    <# Relativní odkazy z REVIEW.md, které nevedou na existující soubor. #>
    param([string[]] $Lines, [string] $Root)
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        foreach ($m in [regex]::Matches($line, '\]\(([^)\s]+)\)')) {
            $target = [uri]::UnescapeDataString(($m.Groups[1].Value -split '#')[0])
            if (-not $target -or $target -match '^[a-z]+:' -or $target.Contains("<")) { continue }
            if (-not (Test-Path -LiteralPath (Join-Path $Root $target))) { $missing.Add($target) }
        }
    }
    return @($missing | Select-Object -Unique)
}

# --- běh ---------------------------------------------------------------------------------------

$resolved = Resolve-Path -LiteralPath $RepoPath -ErrorAction SilentlyContinue
if (-not $resolved) { throw "Cesta '$RepoPath' neexistuje." }
$repoRoot = (& git -C $resolved.Path rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { throw "'$RepoPath' není git repozitář. Zadej cestu k mikroslužbě (např. ../planning)." }
$repoRoot = $repoRoot.Trim()

# Kontrakt repa
if ($ContractPath) {
    $explicit = Resolve-Path -LiteralPath $ContractPath -ErrorAction SilentlyContinue
    if (-not $explicit) { throw "Kontrakt '$ContractPath' neexistuje." }
    $contractPath = $explicit.Path
    Add-Warning "Kontrakt se čte z '$contractPath', ne z kořene repa."
}
else { $contractPath = Join-Path $repoRoot "REVIEW.md" }
$contract = $null
$contractVersion = "none"
$contractLines = @()
$skipGlobs = @($DefaultSkip)
$skipRuleGlobs = @()
$RequiredSections = @("Autority", "Závažnost", "Na co se zaměřit", "Neřeš")
$map = @()
if (Test-Path -LiteralPath $contractPath) {
    $contract = $contractPath
    $contractLines = [System.IO.File]::ReadAllLines($contractPath)
    $fm = Read-Frontmatter $contractPath

    if ($fm.ContainsKey("review-kontrakt")) { $contractVersion = [string] $fm["review-kontrakt"] }
    else { Add-Warning "REVIEW.md nemá v frontmatteru 'review-kontrakt' - čte se jako verze $ContractVersionSupported." }
    if ($contractVersion -ne "none" -and $contractVersion -ne [string] $ContractVersionSupported) {
        Add-Warning "REVIEW.md má verzi kontraktu '$contractVersion', skript umí $ContractVersionSupported - čte se podle verze $ContractVersionSupported."
    }
    if (-not $Base -and $fm.ContainsKey("base") -and $fm["base"]) { $Base = [string] $fm["base"] }
    if ($fm.ContainsKey("vynechat")) { $skipGlobs += @($fm["vynechat"]) }
    if ($fm.ContainsKey("vynechat-pravidla")) { $skipRuleGlobs += @($fm["vynechat-pravidla"]) }

    if ($contractLines.Count -gt $ContractMaxLines) {
        Add-Warning "REVIEW.md má $($contractLines.Count) řádků, limit kontraktu je $ContractMaxLines."
    }
    foreach ($m in (Test-ContractLinks -Lines $contractLines -Root $repoRoot)) {
        Add-Warning "REVIEW.md odkazuje na neexistující soubor: $m"
    }
    foreach ($section in $RequiredSections) {
        if (-not ($contractLines | Where-Object { $_ -match "^##\s+$([regex]::Escape($section))\s*$" })) {
            Add-Warning "REVIEW.md nemá povinnou sekci '## $section'."
        }
    }
    $map = Get-ContractMap $contractLines

    # Glob z mapy, který nesedí na žádný soubor v gitu, je skoro jistě překlep - zdroj by se nikdy nenačetl.
    if ($map.Count -gt 0) {
        $tracked = @(Invoke-Git ls-files)
        foreach ($entry in $map) {
            foreach ($g in $entry.Globs) {
                if (-not ($tracked | Where-Object { Test-GlobMatch -Path $_ -Pattern $g } | Select-Object -First 1)) {
                    Add-Warning "Glob '$g' z mapy REVIEW.md ($($entry.Source)) nesedí na žádný soubor v gitu."
                }
            }
        }
    }
}

# Base: bez parametru a bez kontraktu dev-sprint. Holé jméno větve se přednostně bere z origin -
# lokální kopie bývá pozadu a three-dot proti zastaralé base přimíchá do review cizí commity.
if (-not $Base) { $Base = $DefaultBase }
# Jen jméno větve: ne HEAD a spol., ne commit, ne výraz s ~ ^, ne tag.
$isBranchName = $Base -notmatch '/' -and $Base -notmatch '^[0-9a-f]{7,40}$' -and $Base -notmatch '[~^@]' `
    -and $Base -cnotmatch '^(HEAD|FETCH_HEAD|ORIG_HEAD|MERGE_HEAD)$'
if ($isBranchName) {
    Invoke-Git rev-parse --verify --quiet "refs/tags/$Base" > $null
    if ($LASTEXITCODE -eq 0) { $isBranchName = $false }
}
if ($isBranchName) {
    Invoke-Git rev-parse --verify --quiet "refs/remotes/origin/$Base" > $null
    if ($LASTEXITCODE -eq 0) { $Base = "origin/$Base" }
}
Invoke-Git rev-parse --verify --quiet "$Base^{commit}" > $null
if ($LASTEXITCODE -ne 0) { throw "Base '$Base' neexistuje. Zkus 'origin/dev-sprint', 'git fetch' nebo konkrétní commit." }

if (-not $OutDir) {
    # Hash cesty repa: dvě session nad různými worktrees si vstup nepřepíšou, opakovaný běh
    # v témže worktree přepíše jen svůj výstup.
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash($utf8NoBom.GetBytes($repoRoot)) } finally { $sha.Dispose() }
    $suffix = -join ($hash[0..3] | ForEach-Object { $_.ToString("x2") })
    $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pps-review-" + $suffix)
}
if (Test-Path -LiteralPath $OutDir) {
    # Maže se rekurzivně, takže jen prázdný adresář nebo zjevný výstup předchozího běhu.
    $looksLikeOutput = (Test-Path (Join-Path $OutDir "pr.diff")) -or (Test-Path (Join-Path $OutDir "diff"))
    $isEmpty = @(Get-ChildItem -Force -LiteralPath $OutDir).Count -eq 0
    if (-not ($looksLikeOutput -or $isEmpty)) {
        throw "Adresář '$OutDir' není prázdný a nevypadá jako výstup review. Zvol jiný -OutDir."
    }
    Remove-Item -Recurse -Force -LiteralPath $OutDir
}
$diffDir = Join-Path $OutDir "diff"
New-Item -ItemType Directory -Force -Path $diffDir > $null

# --output= zapisuje git sám: kódování ani konce řádků neprojdou konzolí.
$diffPath = Join-Path $OutDir "pr.diff"
if ($IncludeWorkingTree) {
    $mergeBase = (Invoke-Git merge-base "$Base" HEAD)
    if ($LASTEXITCODE -ne 0) { throw "Společný předek s '$Base' se nenašel." }
    Invoke-Git diff --no-color --no-ext-diff --output="$diffPath" $mergeBase.Trim()
}
else {
    Invoke-Git diff --no-color --no-ext-diff --output="$diffPath" "$Base...HEAD"
}
if ($LASTEXITCODE -ne 0) { throw "git diff selhal (base '$Base')." }

# Co skript neuvidí, musí říct nahlas.
if ($IncludeWorkingTree) {
    $untracked = @(Invoke-Git ls-files --others --exclude-standard)
    if ($untracked.Count -gt 0) {
        Add-Warning "Nesledovaných souborů $($untracked.Count) - v diffu nejsou. Přidej je (git add -N), mají-li se posoudit."
    }
}
else {
    $status = @(Invoke-Git status --porcelain)
    if ($status.Count -gt 0) {
        Add-Warning "Pracovní strom má $($status.Count) změněných nebo nových souborů, které se neposuzují. Commitni je, nebo spusť s -IncludeWorkingTree."
    }
}

function Write-Result {
    param([string] $Rules, [int] $Skipped, [string[]] $Criteria)
    Write-Output "CONTRACT=$(if ($contract) { $contract } else { 'none' })"
    Write-Output "CONTRACT_VERSION=$contractVersion"
    Write-Output "BASE=$Base"
    Write-Output "DIFF_DIR=$diffDir"
    Write-Output "INDEX=$(Join-Path $diffDir 'index.tsv')"
    Write-Output "RULES=$Rules"
    Write-Output "AUTHORITIES=$(if ($authorities.Count -gt 0) { $authorities -join ', ' } else { 'none' })"
    Write-Output "SKIPPED=$Skipped"
    Write-Output "CRITERIA_CHANGED=$(if ($Criteria.Count -gt 0) { $Criteria -join ', ' } else { 'none' })"
    foreach ($w in $warnings) { Write-Output "WARN=$w" }
}

# Autority: z REVIEW.md, jinak fallback. Spolu se zdroji mapy jsou i kritérii review.
$authorities = if ($contract) { @(Get-ContractAuthorities $contractLines) }
               else { @($FallbackAuthorities | Where-Object { Test-Path -LiteralPath (Join-Path $repoRoot $_) }) }
$CriteriaGlobs += @($authorities) + @($map | ForEach-Object { $_.Source })

$rulesPath = Join-Path $OutDir "review-rules.tsv"
$diffLines =[System.IO.File]::ReadAllLines($diffPath, $utf8NoBom)
if ($diffLines.Count -eq 0) {
    Write-TextFile (Join-Path $diffDir "index.tsv") @()
    Write-TextFile $rulesPath @()
    Add-Warning "Proti '$Base' není žádná změna - není co posuzovat."
    Write-Result -Rules $rulesPath -Skipped 0 -Criteria @()
    exit 0
}

# Patche: vynechané soubory se nezapíšou, jen se spočítají.
$items = Split-Diff $diffLines
$index = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$changed = New-Object System.Collections.Generic.List[string]
$n = 0
foreach ($item in $items) {
    if (Test-AnyGlob -Path $item.Path -Globs $skipGlobs) { $skipped.Add($item.Path); continue }
    $n++
    $name = "{0:d3}.patch" -f $n
    Write-TextFile (Join-Path $diffDir $name) (ConvertTo-AnnotatedPatch $item.Lines.ToArray())
    $index.Add(("{0}`t{1}`t+{2}/-{3}" -f $name, $item.Path, $item.Added, $item.Deleted))
    $changed.Add($item.Path)
}
Write-TextFile (Join-Path $diffDir "index.tsv") $index.ToArray()
Write-TextFile (Join-Path $OutDir "skipped.txt") $skipped.ToArray()

# Změna kritérií (počítá se ze všech změněných souborů, i vynechaných).
$criteria = @($items | Where-Object { Test-AnyGlob -Path $_.Path -Globs $CriteriaGlobs } | ForEach-Object { $_.Path })

# Výběr pravidel. Řádek: cesta <TAB> důvod (paths:<glob> | vždy | mapa:<glob> | popis).
# V repech s ai-rulez je zdrojem .ai-rulez/rules; stejnojmenný vygenerovaný soubor v .claude/rules se přeskočí.
$selected = New-Object System.Collections.Generic.List[string]
$seenNames = @{}
foreach ($dir in @(".ai-rulez/rules", ".claude/rules")) {
    $full = Join-Path $repoRoot $dir
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($rule in (Get-ChildItem -LiteralPath $full -Filter *.md -File -Recurse | Sort-Object FullName)) {
        $rel = [System.IO.Path]::GetRelativePath($repoRoot, $rule.FullName).Replace("\", "/")
        $key = $rule.Name.ToLowerInvariant()
        if ($seenNames.ContainsKey($key)) { continue }
        $seenNames[$key] = $true
        # Pravidla, která se kódu netýkají (workflow, OpenSpec bridge), vypíná REVIEW.md klíčem `vynechat-pravidla`.
        if ($skipRuleGlobs.Count -gt 0 -and (Test-AnyGlob -Path $rel -Globs $skipRuleGlobs)) { continue }

        $fm = Read-Frontmatter $rule.FullName
        $activation = if ($fm.ContainsKey("activation")) { [string] $fm["activation"] } else { "" }
        if ($fm.ContainsKey("apply") -and -not $activation) { $activation = [string] $fm["apply"] }
        if ($activation -eq "manual") { continue }

        $globs = Get-RuleGlobs $fm
        if ($globs.Count -gt 0) {
            $hit = $null
            foreach ($g in $globs) {
                foreach ($p in $changed) { if (Test-GlobMatch -Path $p -Pattern $g) { $hit = $g; break } }
                if ($hit) { break }
            }
            if ($hit) { $selected.Add("$rel`tpaths:$hit") }
        }
        elseif ($activation -eq "auto") { $selected.Add("$rel`tpopis") }
        else { $selected.Add("$rel`tvždy") }
    }
}
foreach ($entry in $map) {
    $hit = $null
    foreach ($g in $entry.Globs) {
        foreach ($p in $changed) { if (Test-GlobMatch -Path $p -Pattern $g) { $hit = $g; break } }
        if ($hit) { break }
    }
    if ($hit) { $selected.Add("$($entry.Source)`tmapa:$hit") }
}
Write-TextFile $rulesPath $selected.ToArray()

Write-Result -Rules $rulesPath -Skipped $skipped.Count -Criteria $criteria
