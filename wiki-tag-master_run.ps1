# === Master Run ===

$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$excludeDirs = @("Archive","Templates")

# Markdown-friendly link for wiki footers
$dictLink = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md"

# Filesystem path for writing the dictionary file
$dictWritePath = "Tags\Tag_Dictionary.md"

$logPath = Join-Path $repoRoot "TagUpdate.log"

"=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logPath -Encoding UTF8
"Using Tag Dictionary link: $dictLink" | Out-File -FilePath $logPath -Append

# === Include root-level file named after the repo folder ===
$rootName = Split-Path $repoRoot -Leaf
$parentDir = Split-Path $repoRoot -Parent
$rootLevelFile = Join-Path $parentDir "$rootName.md"

$files = @()
if (Test-Path $rootLevelFile) {
    $files += Get-Item $rootLevelFile
    "Included root-level file: $rootLevelFile" | Out-File -FilePath $logPath -Append
}

# === Add all .md files inside repoRoot, excluding specified dirs ===
$files += Get-ChildItem -Path $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch "\\($($excludeDirs -join '|'))\\" }

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryLink $dictLink -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        $content = Get-Content -Path $f.FullName -Raw

        $expectedLink = "[Tag Dictionary]($dictLink)"
        $headerPattern = "(?s)^---.*?---\s*"
        $footerPattern = "(?s)---\s*\*\*Tags:\*\*.*?\[Tag Dictionary\]\(.*?\)\s*---"
        
        $hasHeader = $content -match $headerPattern
        $hasFooter = $content -match $footerPattern
        
        # --- Extract existing tags if present ---
        $existingTags = @()
        if ($hasHeader) {
            if ($content -match "(?s)^---.*?tags:(.*?)---") {
                $raw = $matches[1] -split "`r?`n"
                $existingTags = $raw -replace "^\s*-\s*", "" | Where-Object { $_ -ne "" }
            }
        }
        
        # Compare sets
        $tagsDiffer = (@($existingTags | Sort-Object) -join ',') -ne (@($result.Tags | Sort-Object) -join ',')
        
        if (-not $hasHeader -or -not $hasFooter -or $tagsDiffer) {
            $backup = "$($f.FullName).bak"
            if (-not (Test-Path $backup)) {
                Copy-Item -Path $f.FullName -Destination $backup
                "Backup created: $($result.Path)" | Out-File -FilePath $logPath -Append
            }
        
            if ($hasHeader) { $content = $content -replace $headerPattern, "" }
            if ($hasFooter) { $content = $content -replace $footerPattern, "" }
        
            $newContent = $result.YAML + "`r`n" + $content.TrimEnd() + "`r`n" + $result.Footer
            Set-Content -Path $f.FullName -Value $newContent
            "Updated (tags changed): $($result.Path)" | Out-File -FilePath $logPath -Append
        }
        else {
            "Skipped (tags already correct): $($result.Path)" | Out-File -FilePath $logPath -Append
        }
    }
}

# === Write Tag Dictionary ===

$dictTargetPath = Join-Path $repoRoot $dictWritePath
$dictTargetDir = Split-Path $dictTargetPath -Parent

if (-not (Test-Path $dictTargetDir)) {
    New-Item -Path $dictTargetDir -ItemType Directory | Out-Null
}

$uniqueTags = $allTags | Sort-Object -Unique
@(
    "# Tag Dictionary"
    ""
    "This file lists all unique tags generated from the wiki structure."
    ""
    foreach ($t in $uniqueTags) { "- $t" }
) | Set-Content -Path $dictTargetPath

"Tag dictionary written to $dictWritePath" | Out-File -FilePath $logPath -Append
