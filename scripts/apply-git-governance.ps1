#Requires -Version 5.1
<#
.SYNOPSIS
  Apply standard git governance files to portfolio repositories.

.DESCRIPTION
  Copies templates/github-governance into each target repo, commits on a
  feature branch, pushes, opens a PR, and squash-merges. Skips
  devops-git-github-lab (reference implementation).

.PARAMETER RepoPath
  Optional single repo path. If omitted, applies to hub + all repos/ except git-github-lab.

.PARAMETER Push
  Push branch and open PR. Default: true.

.PARAMETER DirectMain
  Commit directly to main instead of using a PR branch (not recommended).
#>
param(
    [string]$RepoPath,
    [switch]$Push = $true,
    [switch]$DirectMain
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & git @Args 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0) { throw "git $($Args -join ' ') failed: $output" }
    return $output
}

function Invoke-GitQuiet {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    & git @Args 2>&1 | Out-Null
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return $code
}
$HubRoot = Split-Path -Parent $PSScriptRoot
$TemplateRoot = Join-Path $HubRoot 'templates\github-governance'
$GitEmail = '77498742+Deonarayankumar@users.noreply.github.com'
$GitName = 'Deonarayankumar'
$SkipRepo = 'devops-git-github-lab'
$TerraformRepos = @(
    'devops-terraform-lab',
    'devops-azure-lab',
    'devops-aws-lab',
    'devops-e2e-terraform-azure'
)

function Get-TargetRepos {
    param([string]$SinglePath)

    if ($SinglePath) {
        return @((Resolve-Path $SinglePath).Path)
    }

    $targets = @($HubRoot)
    $reposDir = Join-Path $HubRoot 'repos'
    if (Test-Path $reposDir) {
        Get-ChildItem $reposDir -Directory | ForEach-Object {
            if ($_.Name -ne $SkipRepo) {
                $targets += $_.FullName
            }
        }
    }
    return $targets
}

function Copy-GovernanceFiles {
    param(
        [string]$Destination,
        [string]$RepoName
    )

    $files = @(
        @{ Src = 'CODEOWNERS'; Dst = 'CODEOWNERS' },
        @{ Src = 'CONTRIBUTING.md'; Dst = 'CONTRIBUTING.md' },
        @{ Src = 'docs\branching-strategy.md'; Dst = 'docs\branching-strategy.md' },
        @{ Src = '.github\workflows\governance.yml'; Dst = '.github\workflows\governance.yml' }
    )

    foreach ($file in $files) {
        $srcPath = Join-Path $TemplateRoot $file.Src
        $dstPath = Join-Path $Destination $file.Dst
        $dstDir = Split-Path $dstPath -Parent
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -Path $srcPath -Destination $dstPath -Force
    }

    $prTemplate = if ($TerraformRepos -contains $RepoName) {
        '.github\pull_request_template.terraform.md'
    } else {
        '.github\pull_request_template.md'
    }
    $prSrc = Join-Path $TemplateRoot $prTemplate
    $prDst = Join-Path $Destination '.github\pull_request_template.md'
    $prDir = Split-Path $prDst -Parent
    if (-not (Test-Path $prDir)) {
        New-Item -ItemType Directory -Path $prDir -Force | Out-Null
    }
    Copy-Item -Path $prSrc -Destination $prDst -Force
}

function Ensure-GitIdentity {
    param([string]$Path)
    Push-Location $Path
    try {
        git config user.email $GitEmail
        git config user.name $GitName
    } finally {
        Pop-Location
    }
}

function Apply-ToRepo {
    param([string]$Path)

    $repoName = Split-Path $Path -Leaf
    if ($repoName -eq 'LLM-code') { $repoName = 'devops-portfolio-hub' }

    Write-Host "`n=== $repoName ===" -ForegroundColor Cyan

    if (-not (Test-Path (Join-Path $Path '.git'))) {
        Write-Warning "Skipping $repoName - not a git repository"
        return
    }

    Push-Location $Path
    try {
        Ensure-GitIdentity -Path $Path
        Invoke-GitQuiet fetch origin --quiet
        if ((Invoke-GitQuiet checkout main) -ne 0) {
            if ((Invoke-GitQuiet checkout master) -ne 0) { throw 'No main or master branch' }
        }
        Invoke-GitQuiet pull --ff-only origin HEAD

        $branch = if ($DirectMain) { (git branch --show-current).Trim() } else { 'chore/git-governance' }
        if (-not $DirectMain) {
            Invoke-Git checkout -B $branch | Out-Null
        }

        Copy-GovernanceFiles -Destination $Path -RepoName $repoName

        $status = git status --porcelain
        if (-not $status) {
            Write-Host "No changes needed for $repoName"
            return
        }

        Invoke-Git add CODEOWNERS CONTRIBUTING.md docs .github | Out-Null
        if ($repoName -eq 'devops-portfolio-hub') {
            Invoke-Git add templates scripts README.md | Out-Null
        }
        Invoke-Git commit -m "chore: add git governance policies" -m "- CODEOWNERS, CONTRIBUTING, branching strategy doc" -m "- PR template and Governance CI workflow" | Out-Null

        if (-not $Push) {
            Write-Host "Committed locally (not pushed)"
            return
        }

        if ($DirectMain) {
            Invoke-Git push origin HEAD | Out-Null
            return
        }

        Invoke-Git push -u origin $branch --force-with-lease | Out-Null

        $existingPr = gh pr list --head $branch --json number --jq '.[0].number' 2>$null
        if ($existingPr) {
            gh pr merge $existingPr --squash --delete-branch
            Write-Host "Merged existing PR #$existingPr"
        } else {
            $prUrl = gh pr create --title "chore: add git governance policies" --body "Adds standard portfolio git governance: CODEOWNERS, CONTRIBUTING, branching strategy, PR template, and Governance CI workflow."
            $prNumber = gh pr list --head $branch --json number --jq '.[0].number'
            gh pr merge $prNumber --squash --delete-branch
            Write-Host "Created and merged: $prUrl"
        }

        if ((Invoke-GitQuiet checkout main) -ne 0) {
            Invoke-GitQuiet checkout master | Out-Null
        }
        Invoke-GitQuiet pull --ff-only origin HEAD
    } finally {
        Pop-Location
    }
}

$targets = Get-TargetRepos -SinglePath $RepoPath
foreach ($target in $targets) {
    Apply-ToRepo -Path $target
}

Write-Host "`nDone. Run scripts/apply-branch-protection.ps1 to enable main branch rules." -ForegroundColor Green
