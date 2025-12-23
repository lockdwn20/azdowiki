# === Master Run ===
#Params allows for pipeline pass through, current variables are set for local update
param(
    [string]$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root" #Repo root can be set for local or automated container
    [string[]]$excludeDirs = @("Archive","Templates")  #Can be replaced with additional excluded directories
    [string]$backupMode = "<Mode>" #Create, Delete or None mode for backup files
    # Markdown-friendly link for wiki footers
    [string]$dictLink = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md"
    # Filesystem path for writing the dictionary file
    [string]$dictWritePath = "Tags\Tag_Dictionary.md"
)

#All Wiki Metadata Functions
Import-Module -Name "$PSScriptRoot\WikiTools.psm1"

#Set and Clear Log Path
$logPath = Join-Path $repoRoot "TagUpdate.log"
Set-Content -Path $logPath -Value ""

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
