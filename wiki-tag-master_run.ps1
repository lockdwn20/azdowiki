# === Master Run ===

$repoRoot = "<ex. C:\User\GITUSER\GIT\Wiki\Wiki-Root>"
$excludeDirs = @("<ex. Archive>","<ex. Templates>")
$logPath = Join-Path $repoRoot "<ex. SubDir\TagUpdate.log>"
$dictPath = Join-Path $repoRoot "<ex. SubDir\TagDictionary.md>"

"=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logPath -Encoding UTF8

$files = Get-ChildItem -Path $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch "\\($($excludeDirs -join '|'))\\" }

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryPath $dictPath -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        $content = Get-Content -Path $f.FullName -Raw

        $hasHeader = $content -match "(?s)^---.*?---"
        $hasFooter = $content -match "<!-- TAG:"

        if (-not $hasHeader -or -not $hasFooter) {
            # Backup
            $backup = "$($f.FullName).bak"
            if (-not (Test-Path $backup)) {
                Copy-Item -Path $f.FullName -Destination $backup
                "Backup created: $($result.Path)" | Out-File -FilePath $logPath -Append
            }

            # Insert header/footer
            $newContent = $content
            if (-not $hasHeader) { $newContent = $result.YAML + "`r`n" + $newContent }
            if (-not $hasFooter) { $newContent = $newContent + "`r`n" + $result.Footer }

            Set-Content -Path $f.FullName -Value $newContent
            "Updated: $($result.Path)" | Out-File -FilePath $logPath -Append
        }
        else {
            "Skipped (already tagged): $($result.Path)" | Out-File -FilePath $logPath -Append
        }
    }
}

# Write Tag Dictionary
$uniqueTags = $allTags | Sort-Object -Unique
@(
    "# Tag Dictionary"
    ""
    "This file lists all unique tags generated from the wiki structure."
    ""
    foreach ($t in $uniqueTags) { "- $t" }
) | Set-Content -Path $dictPath

"Tag dictionary written to $dictPath" | Out-File -FilePath $logPath -Append
