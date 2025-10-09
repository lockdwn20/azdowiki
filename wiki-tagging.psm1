function Get-WikiMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,

        [Parameter(Mandatory=$true)]
        [string]$TagDictionaryLink,

        [string[]]$ExcludeDirs = @()
    )

    $fullPath = Resolve-Path $FilePath
    $relativePath = $fullPath.Path.Substring($RepoRoot.Length).TrimStart('\')
    $segments = $relativePath -split '\\'

    # --- FIX: handle root-level files cleanly ---
    $fileName = [IO.Path]::GetFileNameWithoutExtension($segments[-1])
    if ($segments.Length -gt 1) {
        # Only treat preceding segments as folders if they exist
        $folders = $segments[0..($segments.Length-2)]
    }
    else {
        $folders = @()
    }
    # --------------------------------------------

    # Build exclusion set
    $excludedSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($d in $ExcludeDirs) { [void]$excludedSet.Add($d) }
    if ($folders | Where-Object { $excludedSet.Contains($_) }) { return $null }

    $tags = @()
    foreach ($f in $folders) { $tags += $f -split '-' }
    $tags += $fileName -split '-'

    $rootTag = Split-Path $RepoRoot -Leaf
    if (-not $excludedSet.Contains($rootTag)) { $tags += $rootTag -split '-' }

    $tags = $tags | ForEach-Object {
        $clean = ($_ -replace '\s+', '') -replace '[^a-zA-Z0-9_]'
        if ($clean.Length -gt 0) { $clean }
    } | Where-Object { $_ -ne "" } | Sort-Object -Unique

    $yaml = @()
    $yaml += "---"
    $yaml += "title: $fileName"
    $yaml += "description: "
    $yaml += "tags:"
    foreach ($t in $tags) { $yaml += "  - $t" }
    $yaml += "---"

    $footer = @()
    $footer += "---"
    $footer += "**Tags:** " + (@($tags | ForEach-Object { "#$_" }) -join ", ")
    $footer += ""
    foreach ($t in $tags) { $footer += "<!-- TAG: $t -->" }
    $footer += ""
    $footer += "[Tag Dictionary]($TagDictionaryLink)"
    $footer += "---"

    return @{
        File   = $fileName
        Path   = $relativePath
        YAML   = ($yaml -join "`r`n")
        Footer = ($footer -join "`r`n")
        Tags   = $tags
    }
}
