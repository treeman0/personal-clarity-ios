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

function Get-CommandOutput {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    try {
        return ((& $Command *>&1) | Out-String).Trim()
    } catch {
        return "FAILED: $($_.Exception.Message)"
    }
}

function Format-OneLine {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return (($Value -split "`r?`n") -join " | ").Trim()
}

function Get-GitHubJson {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            return & $Command
        } catch {
            return $null
        }
    }

    return $null
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
        $remoteHead = (git rev-parse origin/main).Trim()
        $runs = gh run list --repo treeman0/personal-clarity-ios --workflow "iOS CI" --branch main --limit 20 --json databaseId,headSha,status,conclusion | ConvertFrom-Json
        $run = $null
        foreach ($candidate in $runs) {
            if ($candidate.headSha -eq $remoteHead) {
                $run = $candidate
                break
            }
        }
        if (-not $run) {
            Write-Output "No iOS CI run found for origin/main $remoteHead."
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

Invoke-OptionalCommand "Acceptance record auto-fill" {
    $gitStatus = Get-CommandOutput { git status -sb }
    $localHead = Get-CommandOutput { git log -1 --oneline }
    $remoteHead = Get-CommandOutput { git log -1 --oneline origin/main }
    $releaseVerifier = Get-CommandOutput { bash scripts/verify-release-config.sh }
    $loopStatus = Get-CommandOutput { & ".\.claude\scripts\status-report.ps1" }
    $loopClean = ($loopStatus -match "pending verification: False") `
        -and ($loopStatus -match "pending wiki review: False") `
        -and ($loopStatus -match "verification waiver present: False") `
        -and ($loopStatus -match "wiki waiver present: False")

    $currentRunsText = "gh unavailable"
    $recentRunsText = "gh unavailable"
    $iosRunText = "not found"
    $codeqlRunText = "not found"
    $artifactText = "not found"
    $repoText = "gh unavailable"
    $securityText = "gh unavailable"
    $alertsText = "gh unavailable"

    $runsJson = Get-GitHubJson {
        gh run list --repo treeman0/personal-clarity-ios --branch main --limit 10 --json databaseId,workflowName,headSha,status,conclusion,url
    }
    if ($runsJson) {
        $runs = $runsJson | ConvertFrom-Json
        $remoteSha = (git rev-parse origin/main).Trim()
        $currentRuns = $runs | Where-Object { $_.headSha -eq $remoteSha }
        if ($currentRuns) {
            $currentRunsText = (($currentRuns | ForEach-Object {
                "$($_.workflowName) $($_.databaseId) $($_.status)/$($_.conclusion) $($_.headSha)"
            }) -join "; ")
        } else {
            $currentRunsText = "no runs found for origin/main $remoteSha"
        }
        $recentRunsText = (($runs | Select-Object -First 3 | ForEach-Object {
            "$($_.workflowName) $($_.databaseId) $($_.status)/$($_.conclusion) $($_.headSha)"
        }) -join "; ")

        $iosRun = $runs | Where-Object { $_.workflowName -eq "iOS CI" -and $_.headSha -eq $remoteSha } | Select-Object -First 1
        $codeqlRun = $runs | Where-Object { $_.workflowName -eq "CodeQL" -and $_.headSha -eq $remoteSha } | Select-Object -First 1

        if ($iosRun) {
            $iosRunText = "run $($iosRun.databaseId), $($iosRun.status)/$($iosRun.conclusion), $($iosRun.headSha), $($iosRun.url)"
            $artifactJson = Get-GitHubJson {
                gh api "repos/treeman0/personal-clarity-ios/actions/runs/$($iosRun.databaseId)/artifacts"
            }
            if ($artifactJson) {
                $artifact = ($artifactJson | ConvertFrom-Json).artifacts |
                    Where-Object { $_.name.StartsWith("clarityhub-xcresult-") } |
                    Select-Object -First 1
                if ($artifact) {
                    $artifactText = "$($artifact.name), expired=$($artifact.expired), size_in_bytes=$($artifact.size_in_bytes)"
                }
            }
        }

        if ($codeqlRun) {
            $codeqlRunText = "run $($codeqlRun.databaseId), $($codeqlRun.status)/$($codeqlRun.conclusion), $($codeqlRun.headSha), $($codeqlRun.url)"
        }
    }

    $repoJson = Get-GitHubJson {
        gh repo view treeman0/personal-clarity-ios --json nameWithOwner,visibility,isPrivate,url
    }
    if ($repoJson) {
        $repo = $repoJson | ConvertFrom-Json
        $repoText = "$($repo.nameWithOwner), visibility=$($repo.visibility), isPrivate=$($repo.isPrivate), $($repo.url)"
    }

    $securityJson = Get-GitHubJson {
        gh api repos/treeman0/personal-clarity-ios --jq '.security_and_analysis'
    }
    if ($securityJson) {
        $securityText = ($securityJson | ConvertFrom-Json | ConvertTo-Json -Compress)
    }

    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            $codeScanningAlerts = gh api repos/treeman0/personal-clarity-ios/code-scanning/alerts --paginate | ConvertFrom-Json
            $secretScanningAlerts = gh api repos/treeman0/personal-clarity-ios/secret-scanning/alerts --paginate | ConvertFrom-Json
            $dependabotAlerts = gh api repos/treeman0/personal-clarity-ios/dependabot/alerts --paginate | ConvertFrom-Json
            $alertsText = "code_scanning_alerts=$($codeScanningAlerts.Count), secret_scanning_alerts=$($secretScanningAlerts.Count), dependabot_alerts=$($dependabotAlerts.Count)"
        } catch {
            $alertsText = "FAILED: $($_.Exception.Message)"
        }
    }

    Write-Output "Candidate commit: $localHead"
    Write-Output "Local/remote status: $(Format-OneLine $gitStatus); remote HEAD: $remoteHead"
    Write-Output "Loop status: $(if ($loopClean) { "clean; no pending verification/wiki gates or waivers" } else { "review Loop status section" })"
    Write-Output "Release verifier: $(Format-OneLine $releaseVerifier)"
    Write-Output "Current release-candidate GitHub Actions runs: $currentRunsText"
    Write-Output "Recent branch GitHub Actions runs: $recentRunsText"
    Write-Output "iOS CI: $iosRunText"
    Write-Output "CodeQL: $codeqlRunText"
    Write-Output "Result bundle artifact: $artifactText"
    Write-Output "Repository visibility: $repoText"
    Write-Output "GitHub security features: $securityText"
    Write-Output "Open security alerts: $alertsText"
    Write-Output "Additional automated coverage: see docs/V1_COMPLETION_AUDIT.md Automated Verification for the named XCTest and SwiftData evidence."
}
