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
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3
    } else {
        Write-Output "gh is not installed or not on PATH."
    }
}
