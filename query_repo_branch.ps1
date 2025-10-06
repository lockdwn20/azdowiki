# === Variables ===
$org        = "https://dev.azure.com/<YourOrg>"
$project    = "<YourProject>"
$pat        = "<PasteYourPAT>"

# === Auth Header ===
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{ Authorization = "Basic $base64AuthInfo" }

# === Step 1: Get all repos in the project ===
$reposUrl = "$org/$project/_apis/git/repositories?api-version=7.0"
$repos = (Invoke-RestMethod -Uri $reposUrl -Headers $headers -Method Get).value

# === Step 2: Filter repos by name (case-insensitive match) ===
$filter = "<filterTerm>"
$filteredRepos = $repos | Where-Object { $_.name -match $filter }

# === Step 3: For each filtered repo, get branches ===
$results = foreach ($repo in $filteredRepos) {
    $branchesUrl = "$org/$project/_apis/git/repositories/$($repo.id)/refs?filter=heads/&api-version=7.0"
    $branches = (Invoke-RestMethod -Uri $branchesUrl -Headers $headers -Method Get).value
    foreach ($branch in $branches) {
        [PSCustomObject]@{
            Repository = $repo.name
            Branch     = $branch.name.Replace("refs/heads/","")
        }
    }
}

# === Step 4: Output ===
$results | Sort-Object Repository, Branch | Format-Table -AutoSize
