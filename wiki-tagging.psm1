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

function Write-WikiMetadataLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Add-Content -Path $LogPath -Encoding ASCII
}

function Get-WikiFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,

        [string[]]$ExcludeDirs = @()
    )

    $files = @()

    # Include root-level file named after the repo folder
    $rootName = Split-Path $RepoRoot -Leaf
    $parentDir = Split-Path $RepoRoot -Parent
    $rootLevelFile = Join-Path $parentDir "$rootName.md"

    if (Test-Path $rootLevelFile) {
        $files += Get-Item $rootLevelFile
    }

    # Add all .md files inside RepoRoot, excluding specified dirs
    $files += Get-ChildItem -Path $RepoRoot -Recurse -File -Filter *.md |
        Where-Object { $_.FullName -notmatch "\\($($ExcludeDirs -join '|'))\\" }

    return $files
}

function Test-WikiMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string[]]$ExpectedTags
    )

    $headerPattern = "(?s)^---.*?---\s*"
    $hasHeader = $Content -match $headerPattern

    $existingTags = @()
    if ($hasHeader) {
        if ($Content -match "(?s)^---.*?tags:(.*?)---") {
            $raw = $matches[1] -split "`r?`n"
            $existingTags = $raw -replace "^\s*-\s*", "" | Where-Object { $_ -ne "" }
        }
    }

    # Compare sorted sets
    $tagsDiffer = (@($existingTags | Sort-Object) -join ',') -ne (@($ExpectedTags | Sort-Object) -join ',')
    return @{
        HasHeader   = $hasHeader
        Existing    = $existingTags
        TagsDiffer  = $tagsDiffer
    }
}

function Backup-WikiFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [ValidateSet("Create","Delete","None")]
        [string]$Mode = "Create"
    )

    $backup = "$FilePath.bak"

    switch ($Mode) {
        "Create" {
            if (-not (Test-Path $backup) {
                Copy-Item -Path $FilePath -Destination $backup
                Write-WikiMetadataLog -Message "Backup created: $FilePath" -LogPath $LogPath
            }
        }
        "Delete" {
            if (Test-Path $backup) {
                Remove-Item $backup -Force
                Write-WikiMetadataLog -Message "Backup deleted: $FilePath" -LogPath $LogPath
            }
        }
        "None" {
            # Do nothing
        }
    }
}

function Update-WikiFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [hashtable]$Metadata,   # Output from Get-WikiMetadata

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter(Mandatory=$true)]
        [string]$DictLink,

        [ValidateSet("Create","Delete","None")]
        [string]$BackupMode = "Create"
    )

    $content = Get-Content -Path $FilePath -Raw

    $headerPattern = "(?s)^---.*?---\s*"
    $footerPattern = "(?s)---\s*\*\*Tags:\*\*.*?\[Tag Dictionary\]\((.*?)\)\s*---"

    $hasHeader = $content -match $headerPattern
    $hasFooter = $content -match $footerPattern
    $existingDictLink = if ($hasFooter) { $matches[1] } else { "" }

    # --- Strip old header/footer first ---
    $body = $content
    if ($hasHeader) { $body = $body -replace $headerPattern, "" }
    if ($hasFooter) { $body = $body -replace $footerPattern, "" }

    # --- Build the new content cleanly ---
    $rebuiltContent = $Metadata.YAML + "`r`n`r`n" + `
                      $body.TrimEnd() + "`r`n`r`n" + `
                      $Metadata.Footer

    # --- Validate tags against rebuilt content ---
    $validation = Test-WikiMetadata -Content $rebuiltContent -ExpectedTags $Metadata.Tags

    # Detect dictionary link drift
    $dictLinkChanged = $existingDictLink -ne $DictLink

    # Normalize for comparison
    $normalizedCurrent = ($content -replace "\r\n", "`n").Trim()
    $normalizedRebuilt = ($rebuiltContent -replace "\r\n", "`n").Trim()

    $formattingDiffers = $normalizedCurrent -ne $normalizedRebuilt

    if (-not $hasHeader -or -not $hasFooter -or $validation.TagsDiffer -or $dictLinkChanged -or $formattingDiffers) {
        Backup-WikiFiles -FilePath $FilePath -LogPath $LogPath -Mode $BackupMode

        Set-Content -Path $FilePath -Value $rebuiltContent -Encoding UTF8
        Write-WikiMetadataLog -Message "Updated (tags/dict link/formatting changed): $($Metadata.Path)" -LogPath $LogPath
    }
    else {
        Write-WikiMetadataLog -Message "Skipped (already correct): $($Metadata.Path)" -LogPath $LogPath
    }

    if ($BackupMode -eq "Delete") {
        Backup-WikiFiles -FilePath $FilePath -LogPath $LogPath -Mode Delete
    }
}

function Write-WikiMetadataDictionary {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,

        [Parameter(Mandatory=$true)]
        [string]$DictWritePath,

        [Parameter(Mandatory=$true)]
        [string[]]$Tags,

        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $dictTargetPath = Join-Path $RepoRoot $DictWritePath
    $dictTargetDir  = Split-Path $dictTargetPath -Parent

    if (-not (Test-Path $dictTargetDir)) {
        New-Item -Path $dictTargetDir -ItemType Directory | Out-Null
        Write-WikiMetadataLog -Message "Created dictionary directory: $dictTargetDir" -LogPath $LogPath
    }

    $uniqueTags = $Tags | Sort-Object -Unique

    $content = @(
        "# Tag Dictionary"
        ""
        "This file lists all unique tags generated from the wiki structure."
        ""
        foreach ($t in $uniqueTags) { "- $t" }
    )

    Set-Content -Path $dictTargetPath -Value $content -Encoding UTF8
    Write-WikiMetadataLog -Message "Tag dictionary written to $DictWritePath with $($uniqueTags.Count) tags" -LogPath $LogPath
}
