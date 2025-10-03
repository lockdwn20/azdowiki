# === Master Run ===

$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$excludeDirs = @("Archive","Templates")
$dictLink = "TagDictionary.md"  # Markdown-friendly relative path for wiki link
$logPath = Join-Path $repoRoot "TagUpdate.log"

"=== Tag Update Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logPath -Encoding UTF8
"Using Tag Dictionary link: $dictLink" | Out-File -FilePath $logPath -Append

$files = Get-ChildItem -Path $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch "\\($($excludeDirs -join '|'))\\" }

$allTags = @()

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -TagDictionaryLink $dictLink -ExcludeDirs $excludeDirs
    if ($null -ne $result) {
        $allTags += $result.Tags
        $content = Get-Content -Path $f.FullName -Raw

        $expectedLink = "[Tag Dictionary]($dictLink)"
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
) | Set-Content -Path (Join-Path $repoRoot $dictLink)

"Tag dictionary written to $dictLink" | Out-File -FilePath $logPath -Append
