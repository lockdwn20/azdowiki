# === Master Run ===
Import-Module -Name "$PSScriptRoot\WikiTools.psm1"
$repoRoot     = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$excludeDirs  = @("Archive","Templates")
$backupMode   = "<Mode>" #Create, Delete or None mode for backup files
# Markdown-friendly link for wiki footers
$dictLink     = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md"

# Filesystem path for writing the dictionary file
$dictWritePath = "Tags\Tag_Dictionary.md"

$logPath = Join-Path $repoRoot "TagUpdate.log"

# Start log
Add-WikiMetadataLog -Message "=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -LogPath $logPath
Add-WikiMetadataLog -Message "Using Tag Dictionary link: $dictLink" -LogPath $logPath

# Discover files
$files = Get-WikiFiles -RepoRoot $repoRoot -ExcludeDirs $excludeDirs
Add-WikiMetadataLog -Message "Discovered $($files.Count) files" -LogPath $logPath

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
