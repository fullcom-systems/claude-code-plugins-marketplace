#Requires -Version 7.0
# Doloží konvenci počtem pro `review-init-pps`: z kolika souborů populace se kolik drží vzoru.
# Populace = soubory v gitu odpovídající -Files, volitelně zúžené na ty, které obsahují -Select.
# Nic nemění, jen čte soubory v gitu.
#
#   pwsh -NoProfile -File review-count.ps1 -RepoPath ../planning -Files 'src/**/*.cs' `
#       -Select ': AbstractEventProcessor<' -Expect 'throw;'
#   -> POPULATION=85  CONFORM=84  MISS=src/.../FooProcessor.cs
#
# Regulární výrazy jsou .NET (case-sensitive, multiline). Výstup: POPULATION=, CONFORM=, MISS= (nejvýš -Show řádků),
# MISS_MORE= (kolik dalších se nevešlo), při chybě ERROR= (exit 1).

[CmdletBinding()]
param(
    [string] $RepoPath = ".",
    # Glob(y) cest v gitu, oddělené čárkou (`src/**/*.cs, tests/**/*.cs`). Výchozí: všechny soubory.
    [string] $Files = "**",
    # Soubor patří do populace, jen když obsahuje tento vzor. Prázdný = všechny soubory z -Files.
    [string] $Select = "",
    # Vzor, který se počítá jako dodržení konvence.
    [Parameter(Mandatory = $true)] [string] $Expect,
    # Obrácená logika: konvence je, že soubor vzor -Expect NEobsahuje (např. žádné `AllowAnonymous`).
    [switch] $Absent,
    [int] $Show = 15
)

$ErrorActionPreference = "Stop"
trap { Write-Output "ERROR=$($_.Exception.Message)"; exit 1 }
Import-Module (Join-Path $PSScriptRoot "ReviewCommon.psm1") -Force

$resolved = Resolve-Path -LiteralPath $RepoPath -ErrorAction SilentlyContinue
if (-not $resolved) { throw "Cesta '$RepoPath' neexistuje." }
$repoRoot = (& git -C $resolved.Path rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { throw "'$RepoPath' není git repozitář." }
$repoRoot = $repoRoot.Trim()

$globs = @(Split-GlobList $Files)
$options = [System.Text.RegularExpressions.RegexOptions]::Multiline
$selectRx = if ($Select) { [regex]::new($Select, $options) } else { $null }
$expectRx = [regex]::new($Expect, $options)

$population = 0
$conform = 0
$miss = New-Object System.Collections.Generic.List[string]
foreach ($path in @(& git -C $repoRoot ls-files)) {
    if (-not (Test-AnyGlob -Path $path -Globs $globs)) { continue }
    $full = Join-Path $repoRoot $path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $text = [System.IO.File]::ReadAllText($full)
    if ($selectRx -and -not $selectRx.IsMatch($text)) { continue }
    $population++
    $ok = $expectRx.IsMatch($text)
    if ($Absent) { $ok = -not $ok }
    if ($ok) { $conform++ } else { $miss.Add($path) }
}

Write-Output "POPULATION=$population"
Write-Output "CONFORM=$conform"
$miss | Select-Object -First $Show | ForEach-Object { Write-Output "MISS=$_" }
if ($miss.Count -gt $Show) { Write-Output "MISS_MORE=$($miss.Count - $Show)" }
