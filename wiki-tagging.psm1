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

    # --- Handle root-level files cleanly ---
    $fileName = [IO.Path]::GetFileNameWithoutExtension($segments[-1])

    # Fallback if fileName is empty (e.g. root-level or malformed path)
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = Split-Path $RepoRoot -Leaf
    }

    if ($segments.Length -gt 1) {
        $folders = $segments[0..($segments.Length-2)]
    }
    else {
        $folders = @()
    }

    # Build exclusion set
    $excludedSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($d in $ExcludeDirs) { [void]$excludedSet.Add($d) }
    if ($folders | Where-Object { $excludedSet.Contains($_) }) { return $null }

    # Build tags from path segments + file name + repo root
    $tags = @()
    foreach ($f in $folders) { $tags += $f -split '-' }
    $tags += $fileName -split '-'

    $rootTag = Split-Path $RepoRoot -Leaf
    if (-not $excludedSet.Contains($rootTag)) { $tags += $rootTag -split '-' }

    $tags = $tags | ForEach-Object {
        $clean = ($_ -replace '\s+', '') -replace '[^a-zA-Z0-9_]'
        if ($clean.Length -gt 0) { $clean }
    } | Where-Object { $_ -ne "" } | Sort-Object -Unique

    # Use helpers to build header/footer
    $header = Build-WikiHeader -Title $fileName -Tags $tags
    $footer = Build-WikiFooter -Tags $tags -DictLink $TagDictionaryLink

    return @{
        File   = $fileName
        Path   = $relativePath
        Header = $header
        Footer = $footer
        Tags   = $tags
    }
}

function Build-WikiHeader {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string[]]$Tags
    )

    $tagsBlock = ($Tags | ForEach-Object { "  - $_" }) -join "`r`n"

@"
---
title: $Title
description:
tags:
$tagsBlock
---
"@
}

function Build-WikiFooter {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Tags,

        [Parameter(Mandatory=$true)]
        [string]$DictLink
    )

    $hashTags   = ($Tags | ForEach-Object { "#$_" }) -join ", "
    $tagComments = $Tags | ForEach-Object { "<!-- TAG: $_ -->" }

@"
---
**Tags:** $hashTags

$($tagComments -join "`r`n")

<!-- BEGIN NOTOC -->
[Tag Dictionary]($DictLink)
<!-- END NOTOC -->

---
"@
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
        [string[]]$ExpectedTags,

        [Parameter(Mandatory=$true)]
        [string]$DictLink
    )

    # --- Detect header/footer anchors ---
    $headerMatches = [regex]::Matches($Content, "(?m)^---\r?\ntitle:")
    $footerMatches = [regex]::Matches($Content, "(?m)^---\r?\n\*\*Tags:\*\*")

    $hasHeader       = $headerMatches.Count -ge 1
    $hasFooter       = $footerMatches.Count -ge 1
    $duplicateHeader = $headerMatches.Count -gt 1
    $duplicateFooter = $footerMatches.Count -gt 1

    # --- Extract header block (first only) ---
    $headerBlock = ""
    if ($hasHeader) {
        $headerPattern = "(?s)^---\s*.*?---"
        $m = [regex]::Match($Content, $headerPattern)
        if ($m.Success) { $headerBlock = $m.Value }
    }

    # --- Parse tags from header ---
    $headerTags = @()
    if ($headerBlock -match "tags:\s*") {
        $lines = $headerBlock -split "`r?`n"
        foreach ($line in $lines) {
            if ($line -match "^\s*-\s*(.+)$") {
                $headerTags += $Matches[1].Trim()
            }
        }
    }

    # --- Extract footer block (first only) ---
    $footerBlock = ""
    if ($hasFooter) {
        $footerPattern = "(?s)^---\s*\*\*Tags:\*\*.*?---"
        $mFooter = [regex]::Match($Content, $footerPattern)
        if ($mFooter.Success) { $footerBlock = $mFooter.Value }
    }

    # --- Parse tags from footer ---
    $footerTags = @()

    if ($footerBlock -match "\*\*Tags:\*\*") {
        # 1. Hashtag line
        if ($footerBlock -match "\*\*Tags:\*\*\s*(.+)") {
            $hashtags = $Matches[1] -split ","
            foreach ($h in $hashtags) {
                $footerTags += ($h.Trim() -replace "^#","")
            }
        }

        # 2. Hidden HTML comments
        $commentMatches = [regex]::Matches($footerBlock, "<!--\s*TAG:\s*(.+?)\s*-->")
        foreach ($m in $commentMatches) {
            $footerTags += $m.Groups[1].Value.Trim()
        }
    }

    # --- Deduplicate ---
    $footerTags = $footerTags | Sort-Object -Unique

    # --- Detect duplicate tags across header/footer ---
    $allTags = $headerTags + $footerTags
    $duplicates = $allTags | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
    $hasDuplicateTags = $duplicates.Count -gt 0

    # --- Compare sets ---
    $headerVsFooterMatch = (@($headerTags | Sort-Object -Unique) -join ",") -eq (@($footerTags | Sort-Object -Unique) -join ",")
    $headerVsExpected    = (@($headerTags | Sort-Object -Unique) -join ",") -eq (@($ExpectedTags | Sort-Object -Unique) -join ",")
    $footerVsExpected    = (@($footerTags | Sort-Object -Unique) -join ",") -eq (@($ExpectedTags | Sort-Object -Unique) -join ",")
    $tagsDiffer = -not ($headerVsFooterMatch -and $headerVsExpected -and $footerVsExpected) -or $hasDuplicateTags

    # --- Detect dictionary link drift ---
    $dictPattern = "\[Tag Dictionary\]\((.*?)\)"
    $existingDictLink = if ($footerBlock -match $dictPattern) { $Matches[1] } else { "" }
    $dictLinkChanged = $existingDictLink -ne $DictLink

    # --- Structure validity ---
    $structureValid = $hasHeader -and $hasFooter -and -not $duplicateHeader -and -not $duplicateFooter

    # --- Build reason string ---
    $reasons = @()
    if (-not $structureValid) {
        if (-not $hasHeader)       { $reasons += "Missing header" }
        if (-not $hasFooter)       { $reasons += "Missing footer" }
        if ($duplicateHeader)      { $reasons += "Duplicate header" }
        if ($duplicateFooter)      { $reasons += "Duplicate footer" }
    }
    if ($tagsDiffer)              { $reasons += "Tag mismatch/duplicates" }
    if ($dictLinkChanged)         { $reasons += "Dictionary link drift" }

    return @{
        NeedsRebuild    = $reasons.Count -gt 0
        StructureValid  = $structureValid
        TagsDiffer      = $tagsDiffer
        DictLinkChanged = $dictLinkChanged
        HeaderTags      = $headerTags
        FooterTags      = $footerTags
        Duplicates      = $duplicates
        Reason          = ($reasons -join "; ")
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
            if (-not (Test-Path $backup)) {
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

    # Read the file content
    $content = Get-Content -Path $FilePath -Raw

    # Run unified validation
    $validation = Test-WikiMetadata -Content $content -ExpectedTags $Metadata.Tags -DictLink $DictLink

    if ($validation.NeedsRebuild) {
        Backup-WikiFiles -FilePath $FilePath -LogPath $LogPath -Mode $BackupMode

        # Strip ALL old headers and footers (including duplicates)
        $body = $content -replace "(?s)^---\r?\ntitle:.*?---", ""
        $body = $body   -replace "(?s)---\r?\n\*\*Tags:\*\*.*?---", ""

        # Normalize body whitespace
        $cleanBody = $body.Trim()

        # Deduplicate tags before rebuild
        $cleanTags = $Metadata.Tags | Sort-Object -Unique

        # Rebuild fresh header + footer with consistent spacing
        $rebuiltContent = (Build-WikiHeader -Title $Metadata.File -Tags $cleanTags) + "`r`n`r`n" +
                          $cleanBody + "`r`n`r`n" +
                          (Build-WikiFooter -Tags $cleanTags -DictLink $DictLink)

        # Normalize line endings and trim trailing whitespace
        $rebuiltContent = ($rebuiltContent -replace "`r?`n", "`r`n").TrimEnd()

        # Write updated file
        Set-Content -Path $FilePath -Value $rebuiltContent -Encoding UTF8

        # Log with reason(s)
        Write-WikiMetadataLog -Message "Updated ($($validation.Reason)): $($Metadata.Path)" -LogPath $LogPath
    }
    else {
        Write-WikiMetadataLog -Message "Skipped (already correct): $($Metadata.Path)" -LogPath $LogPath
    }

    # Optional cleanup of backups
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
