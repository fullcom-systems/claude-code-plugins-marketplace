# Sdílené funkce skriptů review (review-diff.ps1, review-inventory.ps1): globy a YAML frontmatter.
# Jeden zdroj, aby výběr pravidel a inventura repa četly frontmatter a globy stejně.

# --- globy (převzato z Billingu) ---------------------------------------------------------------

function Expand-Braces {
    <# Rozbalí {a,b} na varianty. #>
    param([string] $Pattern)

    $out = @($Pattern)
    $changed = $true
    while ($changed) {
        $changed = $false
        $next = New-Object System.Collections.Generic.List[string]
        foreach ($item in $out) {
            $start = $item.IndexOf("{")
            $end = -1
            $depth = 0
            if ($start -ge 0) {
                for ($i = $start; $i -lt $item.Length; $i++) {
                    if ($item[$i] -eq "{") { $depth++ }
                    elseif ($item[$i] -eq "}") { $depth--; if ($depth -eq 0) { $end = $i; break } }
                }
            }
            if ($end -lt 0) { $next.Add($item); continue }

            $head = $item.Substring(0, $start)
            $body = $item.Substring($start + 1, $end - $start - 1)
            $tail = $item.Substring($end + 1)
            $parts = New-Object System.Collections.Generic.List[string]
            $depth = 0
            $cur = ""
            foreach ($ch in $body.ToCharArray()) {
                if ($ch -eq "," -and $depth -eq 0) { $parts.Add($cur); $cur = ""; continue }
                if ($ch -eq "{") { $depth++ } elseif ($ch -eq "}") { $depth-- }
                $cur += $ch
            }
            $parts.Add($cur)
            foreach ($part in $parts) { $next.Add($head + $part + $tail) }
            $changed = $true
        }
        $out = $next.ToArray()
    }
    return $out
}

function ConvertTo-GlobstarBraces {
    <# `**/` na začátku nebo za `/` = "nula nebo víc adresářů". #>
    param([string] $Pattern)
    return [regex]::Replace($Pattern, '(?<=^|/)\*\*/', '{,**/}')
}

function Test-GlobMatch {
    <#
        Záměrně permisivní: `*` zasáhne i `/`. Nadbytečně načtené pravidlo stojí pár set tokenů,
        nenačtené stojí přesnost review. Porovnání je case-insensitive kvůli Windows.
    #>
    param([string] $Path, [string] $Pattern)
    foreach ($expanded in (Expand-Braces (ConvertTo-GlobstarBraces $Pattern))) {
        $regex = "^" + ([regex]::Escape($expanded) -replace '\\\*', '.*' -replace '\\\?', '.') + "$"
        if ([regex]::IsMatch($Path, $regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { return $true }
    }
    return $false
}

function Test-AnyGlob {
    param([string] $Path, [string[]] $Globs)
    foreach ($g in $Globs) { if (Test-GlobMatch -Path $Path -Pattern $g) { return $true } }
    return $false
}

# --- frontmatter -------------------------------------------------------------------------------

function Split-GlobList {
    <# `a/**, b/*.{cs,ts}` -> dvě položky; čárky uvnitř {} a [] nedělí (jako ai-rulez). #>
    param([string] $Text)
    $parts = New-Object System.Collections.Generic.List[string]
    $depth = 0
    $cur = ""
    foreach ($ch in $Text.ToCharArray()) {
        if ($ch -eq "," -and $depth -eq 0) { $parts.Add($cur); $cur = ""; continue }
        if ($ch -eq "{" -or $ch -eq "[") { $depth++ } elseif ($ch -eq "}" -or $ch -eq "]") { $depth-- }
        $cur += $ch
    }
    $parts.Add($cur)
    return @($parts | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ })
}

function ConvertFrom-YamlScalar {
    <# Hodnota bez uvozovek a bez komentáře: `"a#b"  # pozn.` -> `a#b`, `a  # pozn.` -> `a`. #>
    param([string] $Text)
    $t = $Text.Trim()
    $quoted = [regex]::Match($t, '^(["''])(.*?)\1')
    if ($quoted.Success) { return $quoted.Groups[2].Value }
    return ($t -replace '\s+#.*$', '').Trim()
}

function Read-Frontmatter {
    <#
        Minimalistický čtenář YAML frontmatteru: skaláry `klíč: hodnota` a seznamy (`- položka`
        nebo `[a, b]` na jednom řádku). Na kontrakt a pravidla stačí; plný YAML parser by byl
        závislost navíc, kterou nemá každý stroj.
        Vrací hashtable; bez frontmatteru prázdnou.
    #>
    param([string] $Path)

    $result = @{}
    $lines = [System.IO.File]::ReadAllLines($Path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") { return $result }

    $listKey = $null
    $blockKey = $null
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq "---") { break }

        # Pokračování víceřádkové hodnoty (`description: >-` a odsazené řádky pod ní).
        if ($blockKey) {
            if ($line -match '^\s+\S') {
                $result[$blockKey] = ($result[$blockKey] + " " + $line.Trim()).Trim()
                continue
            }
            $blockKey = $null
        }

        $item = [regex]::Match($line, '^\s*-\s*(.+?)\s*$')
        if ($listKey -and $item.Success) {
            $result[$listKey] += @(ConvertFrom-YamlScalar $item.Groups[1].Value)
            continue
        }

        $kv = [regex]::Match($line, '^([A-Za-z0-9_-]+):\s*(.*)$')
        if (-not $kv.Success) { continue }
        $key = $kv.Groups[1].Value
        $raw = $kv.Groups[2].Value.Trim()
        # Komentář YAML začíná až `#` za mezerou - `C#` v hodnotě komentář není; v uvozovkách neplatí vůbec.
        $value = if ($raw -match '^["'']') { $raw } else { ($raw -replace '\s+#.*$', '').Trim() }
        $listKey = $null

        if ($value -eq "") { $result[$key] = @(); $listKey = $key }
        elseif ($value -match '^[>|][-+]?$') { $result[$key] = ""; $blockKey = $key }
        elseif ($value.StartsWith("[")) { $result[$key] = @(Split-GlobList ($value -replace '\]\s*(#.*)?$', '').TrimStart("[")) }
        else { $result[$key] = ConvertFrom-YamlScalar $value }
    }
    return $result
}

function Get-RuleGlobs {
    <# `paths:` nebo `globs:` jako seznam i jako řetězec oddělený čárkami. #>
    param([hashtable] $Fm)
    foreach ($key in @("paths", "globs")) {
        if (-not $Fm.ContainsKey($key)) { continue }
        $value = $Fm[$key]
        if ($value -is [string]) { return @(Split-GlobList $value) }
        return @($value | ForEach-Object { $_ })
    }
    return @()
}

Export-ModuleMember -Function Expand-Braces, ConvertTo-GlobstarBraces, Test-GlobMatch, Test-AnyGlob, Split-GlobList, Read-Frontmatter, Get-RuleGlobs
