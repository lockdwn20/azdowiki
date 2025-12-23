# === Master Run with Quarterly Review ===
# Params allows for pipeline pass through, current variables are set for local update
param(
    [string]$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root", #Repo root can be set for local or automated container
    [string[]]$excludeDirs = @("Archive","Templates"),  #Can be replaced with additional excluded directories
    [string]$backupMode = "Create", #Create, Delete or None mode for backup files
    # Markdown-friendly link for wiki footers
    [string]$dictLink = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md",
    # Filesystem path for writing the dictionary file
    [string]$dictWritePath = "Tags\Tag_Dictionary.md",
    # Enable/disable quarterly review (set to $false to skip)
    [bool]$enableQuarterlyReview = $true
)

# All Wiki Metadata Functions (including new quarterly review functions)
Import-Module -Name "$PSScriptRoot\WikiTools.psm1" -Force

# Set and Clear Log Path
$logPath = Join-Path $repoRoot "Metadata\Tag_Update.log"

# Ensure Metadata directory exists
$metadataDir = Join-Path $repoRoot "Metadata"
if (-not (Test-Path $metadataDir)) {
    New-Item -Path $metadataDir -ItemType Directory -Force | Out-Null
}

Set-Content -Path $logPath -Value ""

# Start log
Add-WikiMetadataLog -Message "=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -LogPath $logPath
Add-WikiMetadataLog -Message "Using Tag Dictionary link: $dictLink" -LogPath $logPath

# ============================================================================
# QUARTERLY REVIEW PROCESS
# ============================================================================
if ($enableQuarterlyReview) {
    try {
        Invoke-WikiQuarterlyReview `
            -RepoRoot $repoRoot `
            -LogPath $logPath `
            -ExcludeDirs $excludeDirs `
            -ReviewDir "Metadata\Quarterly_Review"
    }
    catch {
        Add-WikiMetadataLog -Message "Quarterly review failed: $_" -LogPath $logPath -Level "ERROR"
        # Continue with tag updates even if quarterly review fails
    }
}
else {
    Add-WikiMetadataLog -Message "Quarterly review disabled - skipping" -LogPath $logPath
}

# ============================================================================
# STANDARD TAG UPDATE PROCESS
# ============================================================================

# Discover files
$files = Get-WikiFiles -RepoRoot $repoRoot -ExcludeDirs $excludeDirs
Add-WikiMetadataLog -Message "Discovered $($files.Count) files for tag processing" -LogPath $logPath

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryLink $dictLink -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        Update-WikiFile -FilePath $f.FullName -Metadata $result -LogPath $logPath -DictLink $dictLink -BackupMode $backupMode
    }
}

# Write dictionary
Save-WikiMetadataDictionary -RepoRoot $repoRoot -DictWritePath $dictWritePath -Tags $allTags -LogPath $logPath

# ============================================================================
# COMPLETION
# ============================================================================
Add-WikiMetadataLog -Message "=== Tag Update Complete ===" -LogPath $logPath

# Output summary to console
Write-Host "`n=== Wiki Update Summary ===" -ForegroundColor Cyan
Write-Host "Files Processed: $($files.Count)" -ForegroundColor Green
Write-Host "Unique Tags: $($allTags | Sort-Object -Unique | Measure-Object).Count" -ForegroundColor Green
Write-Host "Log File: $logPath" -ForegroundColor Yellow

if ($enableQuarterlyReview) {
    $reviewDir = Join-Path $repoRoot "Metadata\Quarterly_Review"
    if (Test-Path $reviewDir) {
        $latestReport = Get-ChildItem -Path $reviewDir -Filter "ChangeReport_*.md" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        
        if ($latestReport) {
            Write-Host "`nLatest Quarterly Review Report:" -ForegroundColor Cyan
            Write-Host $latestReport.FullName -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== Complete ===" -ForegroundColor Cyan
