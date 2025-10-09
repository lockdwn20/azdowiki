# === Master Run ===

$repoRoot     = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$excludeDirs  = @("Archive","Templates")

# Markdown-friendly link for wiki footers
$dictLink     = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md"

# Filesystem path for writing the dictionary file
$dictWritePath = "Tags\Tag_Dictionary.md"

$logPath = Join-Path $repoRoot "TagUpdate.log"

# Start log
Write-WikiMetadataLog -Message "=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -LogPath $logPath
Write-WikiMetadataLog -Message "Using Tag Dictionary link: $dictLink" -LogPath $logPath

# Discover files
$files = Get-WikiFiles -RepoRoot $repoRoot -ExcludeDirs $excludeDirs
Write-WikiMetadataLog -Message "Discovered $($files.Count) files" -LogPath $logPath

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryLink $dictLink -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        Update-WikiFile -FilePath $f.FullName -Metadata $result -LogPath $logPath -DictLink $dictLink
    }
}

# Write dictionary
Write-WikiMetadataDictionary -RepoRoot $repoRoot -DictWritePath $dictWritePath -Tags $allTags -LogPath $logPath
