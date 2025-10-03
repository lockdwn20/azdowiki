function Get-WikiMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,   # e.g. "C:\User\GITUSER\GIT\Wiki\Wiki-Root"

        [string]$TagDictionaryLink = "<Insert_Address>",

        [string[]]$ExcludeDirs = @()   # NEW: directories to skip

    )

    # Resolve full path
    $fullPath = Resolve-Path $FilePath

    # Trim to relative path inside the repo
    $relativePath = $fullPath.Path.Substring($RepoRoot.Length).TrimStart('\')

    # Split into segments
    $segments = $relativePath -split '\\'

    # Extract filename (last element) and folders (everything before it)
    $fileName = [IO.Path]::GetFileNameWithoutExtension($segments[-1])
    $folders  = $segments[0..($segments.Length-2)]

    # Extract tags from folder names
    $tags = @()
    foreach ($f in $folders) {
        # Only split on hyphen, preserve underscores
        $tags += $f -split '-'
    }

    # Add filename as tags (split on hyphen, preserve underscores)
    $tags += $fileName -split '-'

    # Add root folder explicitly
    $rootTag = Split-Path $RepoRoot -Leaf
    if ($ExcludeDirs -notcontains $rootTag) {
        $tags += $rootTag -split '-'
    }

    # Cleanup: strip spaces, allow underscores, preserve original casing
    $tags = $tags | ForEach-Object {
        $clean = ($_ -replace '\s+', '') -replace '[^a-zA-Z0-9_]'
        if ($clean.Length -gt 0) { $clean }
    } | Where-Object { $_ -ne "" }

    # Deduplicate
    $tags = $tags | Sort-Object -Unique

    # YAML block
    $yaml = @()
    $yaml += "---"
    $yaml += "title: $fileName"
    $yaml += "description: "
    $yaml += "tags:"
    foreach ($t in $tags) {
        $yaml += "  - $t"
    }
    $yaml += "---"

    # Footer block
    $footer = @()
    $footer += "---"
    $footer += "**Tags:** " + (($tags | ForEach-Object { "#$_" }) -join ", ")
    $footer += ""
    foreach ($t in $tags) {
        $footer += "<!-- TAG: $t -->"
    }
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
