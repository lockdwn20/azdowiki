# Exclusions (folder names, case-insensitive)
$ExcludeDirs = @("Archive","Templates")

# Build a case-insensitive regex that matches any excluded folder in the path
$escaped = $ExcludeDirs | ForEach-Object { [Regex]::Escape($_) }
$skipPattern = "(?i)\\(" + ($escaped -join "|") + ")(\\|$)"

$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"

# Recurse, but drop any files whose path contains an excluded folder segment
$files = Get-ChildItem -Path $repoRoot -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch $skipPattern }

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot -ExcludeDirs $ExcludeDirs
    if ($null -ne $result) {
        Write-Host "=== $($result.Path) ===" -ForegroundColor Cyan
        Write-Host $result.YAML -ForegroundColor Yellow
        Write-Host $result.Footer -ForegroundColor Green
        Write-Host "`n"
    }
}
