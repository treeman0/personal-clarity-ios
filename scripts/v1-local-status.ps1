Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-OptionalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    Write-Output ""
    Write-Output "## $Name"
    try {
        & $Command
    } catch {
        Write-Output "FAILED: $($_.Exception.Message)"
    }
}

function Invoke-GitHubCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    if (Get-Command gh -ErrorAction SilentlyContinue) {
        & $Command
    } else {
        Write-Output "gh is not installed or not on PATH."
    }
}

Write-Output "# ClarityHub V1 Local Status"
Write-Output "Generated: $((Get-Date).ToString('s'))"

Invoke-OptionalCommand "Git status" {
    git status -sb
}

Invoke-OptionalCommand "Local HEAD" {
    git log -1 --oneline
}

Invoke-OptionalCommand "Remote HEAD" {
    git log -1 --oneline origin/main
}

Invoke-OptionalCommand "Loop status" {
    & ".\.claude\scripts\status-report.ps1"
}

Invoke-OptionalCommand "Release verifier" {
    bash scripts/verify-release-config.sh
}

Invoke-OptionalCommand "Swift test availability" {
    if (Get-Command swift -ErrorAction SilentlyContinue) {
        swift test
    } else {
        Write-Output "swift is not installed on this Windows host; macOS CI is required."
    }
}

Invoke-OptionalCommand "Latest GitHub Actions runs" {
    Invoke-GitHubCommand {
        gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3
    }
}

Invoke-OptionalCommand "Repository visibility and security features" {
    Invoke-GitHubCommand {
        gh repo view treeman0/personal-clarity-ios --json nameWithOwner,visibility,isPrivate,url
        gh api repos/treeman0/personal-clarity-ios --jq '.security_and_analysis'
        gh api repos/treeman0/personal-clarity-ios/automated-security-fixes
    }
}

Invoke-OptionalCommand "Open security alerts" {
    Invoke-GitHubCommand {
        $codeScanningAlerts = gh api repos/treeman0/personal-clarity-ios/code-scanning/alerts --paginate | ConvertFrom-Json
        $secretScanningAlerts = gh api repos/treeman0/personal-clarity-ios/secret-scanning/alerts --paginate | ConvertFrom-Json
        $dependabotAlerts = gh api repos/treeman0/personal-clarity-ios/dependabot/alerts --paginate | ConvertFrom-Json

        Write-Output "code_scanning_alerts=$($codeScanningAlerts.Count)"
        Write-Output "secret_scanning_alerts=$($secretScanningAlerts.Count)"
        Write-Output "dependabot_alerts=$($dependabotAlerts.Count)"
    }
}

Invoke-OptionalCommand "Latest iOS result bundle artifact" {
    Invoke-GitHubCommand {
        $run = gh run list --repo treeman0/personal-clarity-ios --workflow "iOS CI" --branch main --limit 1 --json databaseId,headSha,status,conclusion | ConvertFrom-Json | Select-Object -First 1
        if (-not $run) {
            Write-Output "No iOS CI run found."
            return
        }

        Write-Output "run=$($run.databaseId) head=$($run.headSha) status=$($run.status) conclusion=$($run.conclusion)"
        $artifactsResponse = gh api "repos/treeman0/personal-clarity-ios/actions/runs/$($run.databaseId)/artifacts" | ConvertFrom-Json
        $artifactsResponse.artifacts |
            Where-Object { $_.name.StartsWith("clarityhub-xcresult-") } |
            Select-Object name, expired, size_in_bytes |
            ConvertTo-Json -Compress
    }
}
