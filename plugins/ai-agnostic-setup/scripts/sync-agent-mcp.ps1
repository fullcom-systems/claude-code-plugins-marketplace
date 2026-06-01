# Synchronizuje agent/mcp.json do .mcp.json (Claude) a .cursor/mcp.json (Cursor).
#
# Použití:
#   .\sync-agent-mcp.ps1                        # z <projekt>/scripts/
#   .\sync-agent-mcp.ps1 -RepoRoot C:\Projects\muj-projekt  # odkudkoliv
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [string]$Source
)

$ErrorActionPreference = "Stop"

if (-not $Source) {
    $Source = Join-Path $RepoRoot "agent\mcp.json"
}

$sourcePath = Resolve-Path $Source

$targets = @(
    (Join-Path $RepoRoot ".mcp.json"),
    (Join-Path $RepoRoot ".cursor\mcp.json")
)

$content = Get-Content $sourcePath -Raw -Encoding UTF8
foreach ($target in $targets) {
    $dir = Split-Path $target -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $target -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Synced -> $target"
}

Write-Host "Hotovo. Nastav promenne prostredi a restartuj IDE."
