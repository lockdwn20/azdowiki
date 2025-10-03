# === Master Run ===

$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$excludeDirs = @("Archive","Templates")
$dictPath = "Tag_Dictionary.md"  # Relative path for footer link
$dictFullPath = Join-Path $repoRoot $dictPath
$logPath = Join-Path $repoRoot "Tag_Update.log"

"=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logPath -Encoding UTF8
"Using Tag Dictionary: $dictPath" | Out-File -FilePath $logPath -Append

$files = Get-ChildItem -Path $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch "\\($($excludeDirs -join '|'))\\" }

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryPath $dictPath -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        $content = Get-Content -Path $f.FullName -Raw

        $expectedLink = "[Tag Dictionary]($dictPath)"
        $hasHeader = $content -match "(?s)^---.*?---"
        $hasFooter = $content -match "<!-- TAG:" -and $content -match [Regex]::Escape($expectedLink)

        if (-not $hasHeader -or -not $hasFooter) {
            $backup = "$($f.FullName).bak"
            if (-not (Test-Path $backup)) {
                Copy-Item -Path $f.FullName -Destination $backup
                "Backup created: $($result.Path)" | Out-File -FilePath $logPath -Append
            }

            $newContent = $content
            if (-not $hasHeader) { $newContent = $result.YAML + "`r`n" + $newContent }
            if (-not $hasFooter) { $newContent = $newContent + "`r`n" + $result.Footer }

            Set-Content -Path $f.FullName -Value $newContent
            "Updated: $($result.Path)" | Out-File -FilePath $logPath -Append
        }
        else {
            "Skipped (already tagged and linked): $($result.Path)" | Out-File -FilePath $logPath -Append
        }
    }
}

$uniqueTags = $allTags | Sort-Object -Unique
@(
    "# Tag Dictionary"
    ""
    "This file lists all unique tags generated from the wiki structure."
    ""
    foreach ($t in $uniqueTags) { "- $t" }
) | Set-Content -Path $dictFullPath

"Tag dictionary written to $dictFullPath" | Out-File -FilePath $logPath -Append
