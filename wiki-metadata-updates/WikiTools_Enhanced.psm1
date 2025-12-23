# ============================================================================
# Original WikiTools.psm1 Functions
# ============================================================================

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
    $header = Format-WikiHeader -Title $fileName -Tags $tags
    $footer = Format-WikiFooter -Tags $tags -DictLink $TagDictionaryLink

    return @{
        File   = $fileName
        Path   = $relativePath
        Header = $header
        Footer = $footer
        Tags   = $tags
    }
}

function Format-WikiHeader {
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

function Format-WikiFooter {
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


function Add-WikiMetadataLog {
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
                Add-WikiMetadataLog -Message "Backup created: $FilePath" -LogPath $LogPath
            }
        }
        "Delete" {
            if (Test-Path $backup) {
                Remove-Item $backup -Force
                Add-WikiMetadataLog -Message "Backup deleted: $FilePath" -LogPath $LogPath
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
    # Ensure content is never null or empty
    if ([string]::IsNullOrWhiteSpace($content)) {
        $content = " "
    }

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
        $rebuiltContent = (Format-WikiHeader -Title $Metadata.File -Tags $cleanTags) + "`r`n`r`n" +
                          $cleanBody + "`r`n`r`n" +
                          (Format-WikiFooter -Tags $cleanTags -DictLink $DictLink)

        # Normalize line endings and trim trailing whitespace
        $rebuiltContent = ($rebuiltContent -replace "`r?`n", "`r`n").TrimEnd()

        # Write updated file
        Set-Content -Path $FilePath -Value $rebuiltContent -Encoding UTF8

        # Log with reason(s)
        Add-WikiMetadataLog -Message "Updated ($($validation.Reason)): $($Metadata.Path)" -LogPath $LogPath
    }
    else {
        Add-WikiMetadataLog -Message "Skipped (already correct): $($Metadata.Path)" -LogPath $LogPath
    }

    # Optional cleanup of backups
    if ($BackupMode -eq "Delete") {
        Backup-WikiFiles -FilePath $FilePath -LogPath $LogPath -Mode Delete
    }
}

function Save-WikiMetadataDictionary {
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
        Add-WikiMetadataLog -Message "Created dictionary directory: $dictTargetDir" -LogPath $LogPath
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
    Add-WikiMetadataLog -Message "Tag dictionary written to $DictWritePath with $($uniqueTags.Count) tags" -LogPath $LogPath
}


# ============================================================================
# NEW: Quarterly Baseline & Change Tracking Functions
# ============================================================================

function Get-QuarterInfo {
    <#
    .SYNOPSIS
    Determines the current quarter and returns metadata.
    
    .DESCRIPTION
    Returns quarter string (e.g., "2025_Q1") and the start date of the current quarter.
    #>
    param(
        [Parameter(Mandatory=$false)]
        [datetime]$Date = (Get-Date)
    )

    $year = $Date.Year
    $month = $Date.Month

    $quarter = switch ($month) {
        { $_ -in 1..3 }   { 1 }
        { $_ -in 4..6 }   { 2 }
        { $_ -in 7..9 }   { 3 }
        { $_ -in 10..12 } { 4 }
    }

    $quarterString = "${year}_Q${quarter}"
    
    # Calculate quarter start date
    $startMonth = ($quarter - 1) * 3 + 1
    $startDate = Get-Date -Year $year -Month $startMonth -Day 1 -Hour 0 -Minute 0 -Second 0

    return @{
        Quarter    = $quarterString
        Year       = $year
        QuarterNum = $quarter
        StartDate  = $startDate
    }
}

function Get-PreviousQuarterInfo {
    <#
    .SYNOPSIS
    Returns information about the previous quarter.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$CurrentQuarter  # e.g., "2025_Q1"
    )

    if ($CurrentQuarter -match "^(\d{4})_Q(\d)$") {
        $year = [int]$Matches[1]
        $quarter = [int]$Matches[2]

        if ($quarter -eq 1) {
            $prevYear = $year - 1
            $prevQuarter = 4
        }
        else {
            $prevYear = $year
            $prevQuarter = $quarter - 1
        }

        return "${prevYear}_Q${prevQuarter}"
    }

    return $null
}

function New-WikiQuarterlyBaseline {
    <#
    .SYNOPSIS
    Creates a snapshot of the current wiki structure.
    
    .DESCRIPTION
    Captures all files and directories, storing metadata in JSON format.
    Excludes specified directories from tracking.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,

        [Parameter(Mandatory=$true)]
        [string]$BaselineDir,

        [Parameter(Mandatory=$true)]
        [string]$Quarter,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [string[]]$ExcludeDirs = @()
    )

    Add-WikiMetadataLog -Message "Creating quarterly baseline for $Quarter" -LogPath $LogPath

    # Ensure baseline directory exists
    if (-not (Test-Path $BaselineDir)) {
        New-Item -Path $BaselineDir -ItemType Directory -Force | Out-Null
        Add-WikiMetadataLog -Message "Created baseline directory: $BaselineDir" -LogPath $LogPath
    }

    # Build exclusion pattern for Get-ChildItem
    $excludePattern = if ($ExcludeDirs.Count -gt 0) {
        "\\($($ExcludeDirs -join '|'))\\"
    } else {
        $null
    }

    # Collect all markdown files
    $files = Get-ChildItem -Path $RepoRoot -Recurse -File -Filter *.md |
        Where-Object { 
            if ($excludePattern) {
                $_.FullName -notmatch $excludePattern
            } else {
                $true
            }
        }

    # Collect all directories
    $directories = Get-ChildItem -Path $RepoRoot -Recurse -Directory |
        Where-Object {
            if ($excludePattern) {
                $_.FullName -notmatch $excludePattern
            } else {
                $true
            }
        }

    # Build file metadata
    $fileData = @()
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($RepoRoot.Length).TrimStart('\')
        $directory = Split-Path $relativePath -Parent

        $fileData += @{
            RelativePath = $relativePath
            FileName     = $file.Name
            LastModified = $file.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
            Directory    = if ($directory) { $directory } else { "" }
        }
    }

    # Build directory list
    $dirData = @()
    foreach ($dir in $directories) {
        $relativePath = $dir.FullName.Substring($RepoRoot.Length).TrimStart('\')
        $dirData += $relativePath
    }

    # Create baseline object
    $baseline = @{
        Quarter     = $Quarter
        Timestamp   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        RepoRoot    = Split-Path $RepoRoot -Leaf
        FileCount   = $fileData.Count
        DirCount    = $dirData.Count
        Files       = $fileData
        Directories = $dirData | Sort-Object
    }

    # Write to JSON
    $baselineFile = Join-Path $BaselineDir "Baseline_$Quarter.json"
    $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $baselineFile -Encoding UTF8

    Add-WikiMetadataLog -Message "Baseline created: $baselineFile ($($fileData.Count) files, $($dirData.Count) directories)" -LogPath $LogPath

    return $baselineFile
}

function Compare-WikiQuarterlyBaselines {
    <#
    .SYNOPSIS
    Compares two quarterly baselines and generates a change report.
    
    .DESCRIPTION
    Identifies added, deleted, moved, and renamed files between quarters.
    Outputs a markdown summary report.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PreviousBaselineFile,

        [Parameter(Mandatory=$true)]
        [string]$CurrentBaselineFile,

        [Parameter(Mandatory=$true)]
        [string]$ReportDir,

        [Parameter(Mandatory=$true)]
        [string]$Quarter,

        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    Add-WikiMetadataLog -Message "Comparing baselines for $Quarter" -LogPath $LogPath

    # Load JSON data
    $previous = Get-Content -Path $PreviousBaselineFile -Raw | ConvertFrom-Json
    $current = Get-Content -Path $CurrentBaselineFile -Raw | ConvertFrom-Json

    # Convert to hashtables for easy lookup
    $prevFiles = @{}
    foreach ($f in $previous.Files) {
        $prevFiles[$f.RelativePath] = $f
    }

    $currFiles = @{}
    foreach ($f in $current.Files) {
        $currFiles[$f.RelativePath] = $f
    }

    # Identify changes
    $added = @()
    $deleted = @()
    $movedRenamed = @()

    # Find added and potentially moved/renamed files
    foreach ($currPath in $currFiles.Keys) {
        if (-not $prevFiles.ContainsKey($currPath)) {
            # This file is new or moved/renamed
            $currFile = $currFiles[$currPath]
            
            # Check if a file with the same name exists in previous but different path (moved)
            $matchingPrevFile = $prevFiles.Values | Where-Object { 
                $_.FileName -eq $currFile.FileName -and $_.RelativePath -ne $currPath 
            } | Select-Object -First 1

            if ($matchingPrevFile) {
                # File was moved or renamed
                $movedRenamed += @{
                    OldPath = $matchingPrevFile.RelativePath
                    NewPath = $currPath
                    Type    = if ($matchingPrevFile.Directory -ne $currFile.Directory) { "Moved" } else { "Renamed" }
                }
            }
            else {
                # File is genuinely new
                $added += $currFile
            }
        }
    }

    # Find deleted files (not moved)
    foreach ($prevPath in $prevFiles.Keys) {
        if (-not $currFiles.ContainsKey($prevPath)) {
            $prevFile = $prevFiles[$prevPath]
            
            # Check if this file was moved (already captured above)
            $wasMoved = $movedRenamed | Where-Object { $_.OldPath -eq $prevPath }
            
            if (-not $wasMoved) {
                $deleted += $prevFile
            }
        }
    }

    # Directory changes
    $prevDirs = $previous.Directories | Sort-Object
    $currDirs = $current.Directories | Sort-Object

    $newDirs = $currDirs | Where-Object { $_ -notin $prevDirs }
    $removedDirs = $prevDirs | Where-Object { $_ -notin $currDirs }

    # Generate markdown report
    $report = Generate-QuarterlyChangeReport `
        -Quarter $Quarter `
        -PreviousQuarter $previous.Quarter `
        -Added $added `
        -Deleted $deleted `
        -MovedRenamed $movedRenamed `
        -NewDirectories $newDirs `
        -RemovedDirectories $removedDirs `
        -PreviousFileCount $previous.FileCount `
        -CurrentFileCount $current.FileCount

    # Write report
    $reportFile = Join-Path $ReportDir "ChangeReport_$Quarter.md"
    $report | Set-Content -Path $reportFile -Encoding UTF8

    Add-WikiMetadataLog -Message "Change report created: $reportFile" -LogPath $LogPath
    Add-WikiMetadataLog -Message "Summary - Added: $($added.Count), Deleted: $($deleted.Count), Moved/Renamed: $($movedRenamed.Count)" -LogPath $LogPath

    return $reportFile
}

function Generate-QuarterlyChangeReport {
    <#
    .SYNOPSIS
    Generates a markdown-formatted change report.
    #>
    param(
        [string]$Quarter,
        [string]$PreviousQuarter,
        [array]$Added,
        [array]$Deleted,
        [array]$MovedRenamed,
        [array]$NewDirectories,
        [array]$RemovedDirectories,
        [int]$PreviousFileCount,
        [int]$CurrentFileCount
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $netChange = $CurrentFileCount - $PreviousFileCount

    $report = @"
# Quarterly Wiki Review - $Quarter

**Review Date:** $timestamp  
**Previous Quarter:** $PreviousQuarter  
**Previous File Count:** $PreviousFileCount  
**Current File Count:** $CurrentFileCount  
**Net Change:** $netChange files

---

## 📊 Changes Summary

- **Added:** $($Added.Count) files
- **Deleted:** $($Deleted.Count) files
- **Moved/Renamed:** $($MovedRenamed.Count) files
- **New Directories:** $($NewDirectories.Count)
- **Removed Directories:** $($RemovedDirectories.Count)

---

"@

    # Added Files
    if ($Added.Count -gt 0) {
        $report += @"
## ✅ Added Files ($($Added.Count))

"@
        foreach ($file in ($Added | Sort-Object RelativePath)) {
            $report += "- ``$($file.RelativePath)`` (Modified: $($file.LastModified))`n"
        }
        $report += "`n---`n`n"
    }

    # Deleted Files
    if ($Deleted.Count -gt 0) {
        $report += @"
## ❌ Deleted Files ($($Deleted.Count))

"@
        foreach ($file in ($Deleted | Sort-Object RelativePath)) {
            $report += "- ``$($file.RelativePath)```n"
        }
        $report += "`n---`n`n"
    }

    # Moved/Renamed Files
    if ($MovedRenamed.Count -gt 0) {
        $report += @"
## 🔄 Moved/Renamed Files ($($MovedRenamed.Count))

"@
        foreach ($change in ($MovedRenamed | Sort-Object OldPath)) {
            $report += "- ``$($change.OldPath)`` → ``$($change.NewPath)`` [$($change.Type)]`n"
        }
        $report += "`n---`n`n"
    }

    # New Directories
    if ($NewDirectories.Count -gt 0) {
        $report += @"
## 📁 New Directories ($($NewDirectories.Count))

"@
        foreach ($dir in ($NewDirectories | Sort-Object)) {
            $report += "- ``$dir```n"
        }
        $report += "`n---`n`n"
    }

    # Removed Directories
    if ($RemovedDirectories.Count -gt 0) {
        $report += @"
## 🗑️ Removed Directories ($($RemovedDirectories.Count))

"@
        foreach ($dir in ($RemovedDirectories | Sort-Object)) {
            $report += "- ``$dir```n"
        }
        $report += "`n---`n`n"
    }

    # Footer
    $report += @"
---

## 📋 Review Checklist

Use this report to verify:
- [ ] All new files follow naming conventions (descriptive, hyphen-delimited)
- [ ] Deleted files were intentionally removed or archived
- [ ] Moved/renamed files maintain tag consistency
- [ ] New directories align with wiki organizational structure
- [ ] No orphaned or misplaced content

**Next Review Date:** [Add 3 months from today]

---

*This report was automatically generated by the Wiki Quarterly Review system.*
"@

    return $report
}

function Invoke-WikiQuarterlyReview {
    <#
    .SYNOPSIS
    Main orchestration function for quarterly baseline tracking.
    
    .DESCRIPTION
    Determines the current quarter, creates a baseline, compares with previous quarter if available,
    and manages retention (keeps only 4 quarters of data).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoRoot,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [string[]]$ExcludeDirs = @(),

        [string]$ReviewDir = "Metadata\Quarterly_Review"
    )

    Add-WikiMetadataLog -Message "=== Starting Quarterly Review Process ===" -LogPath $LogPath

    # Get current quarter info
    $quarterInfo = Get-QuarterInfo
    $currentQuarter = $quarterInfo.Quarter

    # Set up directories
    $baselineDir = Join-Path $RepoRoot $ReviewDir
    $currentBaselineFile = Join-Path $baselineDir "Baseline_$currentQuarter.json"

    # Check if baseline already exists for this quarter
    if (Test-Path $currentBaselineFile) {
        Add-WikiMetadataLog -Message "Baseline already exists for $currentQuarter - skipping creation" -LogPath $LogPath
        return
    }

    # Create current baseline
    New-WikiQuarterlyBaseline `
        -RepoRoot $RepoRoot `
        -BaselineDir $baselineDir `
        -Quarter $currentQuarter `
        -LogPath $LogPath `
        -ExcludeDirs $ExcludeDirs

    # Check for previous quarter baseline
    $previousQuarter = Get-PreviousQuarterInfo -CurrentQuarter $currentQuarter
    $previousBaselineFile = Join-Path $baselineDir "Baseline_$previousQuarter.json"

    if (Test-Path $previousBaselineFile) {
        # Compare and generate report
        Compare-WikiQuarterlyBaselines `
            -PreviousBaselineFile $previousBaselineFile `
            -CurrentBaselineFile $currentBaselineFile `
            -ReportDir $baselineDir `
            -Quarter $currentQuarter `
            -LogPath $LogPath
    }
    else {
        Add-WikiMetadataLog -Message "No previous baseline found - this is the initial baseline" -LogPath $LogPath -Level "INFO"
        
        # Create initial report
        $initialReport = @"
# Quarterly Wiki Review - $currentQuarter

**Review Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Status:** Initial Baseline

---

## 📊 Initial Baseline Created

This is the first quarterly baseline for the wiki. Future quarterly reviews will compare against this baseline to track changes.

**Files Tracked:** $(( Get-Content $currentBaselineFile | ConvertFrom-Json ).FileCount)  
**Directories Tracked:** $(( Get-Content $currentBaselineFile | ConvertFrom-Json ).DirCount)

---

## 📋 Next Steps

1. Review the baseline data to ensure accuracy
2. Verify that excluded directories are properly configured
3. Schedule next review for: [Add 3 months from today]

---

*This is the initial baseline. Change tracking will begin in the next quarter.*
"@
        
        $reportFile = Join-Path $baselineDir "ChangeReport_$currentQuarter.md"
        $initialReport | Set-Content -Path $reportFile -Encoding UTF8
        Add-WikiMetadataLog -Message "Initial baseline report created: $reportFile" -LogPath $LogPath
    }

    # Manage retention - keep only 4 quarters (1 year)
    $allBaselines = Get-ChildItem -Path $baselineDir -Filter "Baseline_*.json" |
        Sort-Object Name -Descending

    if ($allBaselines.Count -gt 4) {
        $toDelete = $allBaselines | Select-Object -Skip 4
        foreach ($oldBaseline in $toDelete) {
            Remove-Item $oldBaseline.FullName -Force
            Add-WikiMetadataLog -Message "Removed old baseline: $($oldBaseline.Name)" -LogPath $LogPath
            
            # Also remove corresponding report
            $reportName = $oldBaseline.Name -replace "^Baseline_", "ChangeReport_" -replace "\.json$", ".md"
            $reportPath = Join-Path $baselineDir $reportName
            if (Test-Path $reportPath) {
                Remove-Item $reportPath -Force
                Add-WikiMetadataLog -Message "Removed old report: $reportName" -LogPath $LogPath
            }
        }
    }

    Add-WikiMetadataLog -Message "=== Quarterly Review Process Complete ===" -LogPath $LogPath
}

# Export all functions
Export-ModuleMember -Function @(
    'Get-WikiMetadata',
    'Format-WikiHeader',
    'Format-WikiFooter',
    'Add-WikiMetadataLog',
    'Get-WikiFiles',
    'Test-WikiMetadata',
    'Backup-WikiFiles',
    'Update-WikiFile',
    'Save-WikiMetadataDictionary',
    'Get-QuarterInfo',
    'Get-PreviousQuarterInfo',
    'New-WikiQuarterlyBaseline',
    'Compare-WikiQuarterlyBaselines',
    'Generate-QuarterlyChangeReport',
    'Invoke-WikiQuarterlyReview'
)
