#Requires -Version 5.1
<#
.SYNOPSIS
  Enable branch protection on main for portfolio repositories.

.DESCRIPTION
  Configures main branch protection: no force-push, require Governance CI
  status check. Skips devops-git-github-lab.

.PARAMETER Repo
  Optional single GitHub repo name (e.g. cloud-resume). If omitted, applies to all portfolio repos.
#>
param(
    [string]$Repo
)

$ErrorActionPreference = 'Stop'
$Owner = 'Deonarayankumar'
$SkipRepo = 'devops-git-github-lab'

$PortfolioRepos = @(
    'devops-portfolio-hub',
    'cloud-resume',
    'devops-linux-bash-lab',
    'devops-python-devops-lab',
    'devops-networking-lab',
    'devops-azure-lab',
    'devops-aws-lab',
    'devops-terraform-lab',
    'devops-docker-lab',
    'devops-cicd-tools-lab',
    'devops-kubernetes-lab',
    'devops-e2e-python-pipeline',
    'devops-e2e-terraform-azure',
    'devops-e2e-k8s-delivery'
)

$targets = if ($Repo) { @($Repo) } else { $PortfolioRepos }

$payload = @'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["validate"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_linear_history": false
}
'@

$tmp = Join-Path $env:TEMP "branch-protection-$([guid]::NewGuid()).json"
[System.IO.File]::WriteAllText($tmp, $payload)

foreach ($name in $targets) {
    if ($name -eq $SkipRepo) { continue }

    Write-Host "Protecting $Owner/$name main..." -ForegroundColor Cyan
    gh api "repos/$Owner/$name/branches/main/protection" -X PUT --input $tmp
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Warning "  Failed for $name (exit $LASTEXITCODE)"
    }
}

Remove-Item $tmp -Force -ErrorAction SilentlyContinue
Write-Host "`nBranch protection applied." -ForegroundColor Green
