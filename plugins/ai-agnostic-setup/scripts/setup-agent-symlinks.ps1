# Vytvoří junction/symlink .cursor/skills a .claude/skills -> skills/
# Windows: junction (mklink /J, nevyžaduje admin ani Developer Mode).
# macOS/Linux (pwsh): symbolický odkaz (ln -sfn).
#
# Použití:
#   .\setup-agent-symlinks.ps1                        # z <projekt>/scripts/
#   .\setup-agent-symlinks.ps1 -RepoRoot C:\Projects\muj-projekt  # odkudkoliv
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$ErrorActionPreference = "Stop"
$skillsPath = Join-Path $RepoRoot "skills"

if (-not (Test-Path $skillsPath)) {
    throw "Chybí složka skills: $skillsPath"
}

# $IsWindows je definované jen v PowerShell 7+; ve Windows PowerShell 5.1 chybí → ber jako Windows.
$onWindows = (-not (Test-Path Variable:\IsWindows)) -or $IsWindows

function Set-SkillsLink {
    param([string]$LinkPath)
    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        if (($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") -and $item.Target -eq $skillsPath) {
            Write-Host "OK (již existuje): $LinkPath"
            return
        }
        Remove-Item $LinkPath -Recurse -Force
    }
    $parent = Split-Path $LinkPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ($onWindows) {
        cmd /c mklink /J "`"$LinkPath`"" "`"$skillsPath`"" | Out-Null
        Write-Host "Junction: $LinkPath -> $skillsPath"
    }
    else {
        ln -sfn "$skillsPath" "$LinkPath"
        Write-Host "Symlink: $LinkPath -> $skillsPath"
    }
}

Set-SkillsLink (Join-Path $RepoRoot ".cursor\skills")
Set-SkillsLink (Join-Path $RepoRoot ".claude\skills")
Write-Host "Hotovo."
