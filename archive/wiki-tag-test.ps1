$repoRoot = "C:\User\GITUSER\GIT\Wiki\Wiki-Root"
$files = Get-ChildItem -Path $repoRoot -Recurse -Filter *.md

foreach ($f in $files) {
    $result = Get-WikiMetadata -FilePath $f.FullName -RepoRoot $repoRoot
    Write-Host "=== $($result.Path) ===" -ForegroundColor Cyan
    Write-Host $result.YAML -ForegroundColor Yellow
    Write-Host $result.Footer -ForegroundColor Green
    Write-Host "`n"
}

