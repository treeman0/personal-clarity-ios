Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $PSScriptRoot "test-v1-acceptance-record.ps1"
$generator = Join-Path $PSScriptRoot "new-v1-acceptance-record.ps1"
$powershellExe = (Get-Process -Id $PID).Path
$tempRecordPaths = [System.Collections.Generic.List[string]]::new()

function New-TempRecordPath {
    $path = Join-Path ([IO.Path]::GetTempPath()) ("v1-acceptance-tooling-" + [guid]::NewGuid().ToString("N") + ".md")
    $script:tempRecordPaths.Add($path) | Out-Null
    return $path
}

function Remove-TempRecords {
    foreach ($path in $script:tempRecordPaths) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Write-Record {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $GoogleOAuthAvailable,
        [Parameter(Mandatory = $true)]
        [string] $CalAIHealthState,
        [string] $CandidateCommit = "5ac2a6f Keep nutrition import matches on one line",
        [string] $EvidenceSha = "5ac2a6f73af705754b35052f6e3b4f428d6f6d8f",
        [string] $ScreenshotsCaptured = "yes"
    )

    @"
Candidate commit: $CandidateCommit
Date: 2026-07-03
Tester: Acceptance tooling smoke
Device or simulator: iPhone simulator
iOS version: 18.5
Apple ID / iCloud state: signed in
HealthKit data state: sample data available
Google OAuth client ID available: $GoogleOAuthAvailable
Cal AI writes nutrition to Apple Health: $CalAIHealthState
Local/remote status: ## main...origin/main; remote HEAD: $EvidenceSha Keep nutrition import matches on one line
Loop status: clean; no pending verification/wiki gates or waivers
Release verifier: Release configuration verified.
Current release-candidate GitHub Actions runs: iOS CI 28647723901 completed/success $EvidenceSha; CodeQL 28647723993 completed/success $EvidenceSha
Recent branch GitHub Actions runs: iOS CI 28647723901 completed/success $EvidenceSha
iOS CI: run 28647723901, completed/success, $EvidenceSha, https://github.com/treeman0/personal-clarity-ios/actions/runs/28647723901
CodeQL: run 28647723993, completed/success, $EvidenceSha, https://github.com/treeman0/personal-clarity-ios/actions/runs/28647723993
Result bundle artifact: clarityhub-xcresult-$EvidenceSha, expired=False, size_in_bytes=9594107
Repository visibility: treeman0/personal-clarity-ios, visibility=PUBLIC, isPrivate=False, https://github.com/treeman0/personal-clarity-ios
GitHub security features: {"dependabot_security_updates":{"status":"enabled"},"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}
Open security alerts: code_scanning_alerts=0, secret_scanning_alerts=0, dependabot_alerts=0
Additional automated coverage: validator smoke
Light mode empty states pass/fail: pass
Dark mode empty states pass/fail: pass
Goals pass/fail: pass
Habits pass/fail: pass
Lists/projects/tasks pass/fail: pass
Review pass/fail: pass
Nutrition pass/fail: pass
Today pass/fail: pass
Dense data pass/fail: pass
Long text pass/fail: pass
HealthKit pass/fail: pass
Notifications pass/fail: pass
Google Calendar pass/fail: pass
Nutrition integration pass/fail: pass
Relaunch persistence pass/fail: pass
Private CloudKit sync pass/fail/not available: pass
Notes: completed
Screenshots captured: $ScreenshotsCaptured
Accepted for V1: yes
Reason: Manual acceptance passed for the release candidate.
Reviewer: Acceptance tooling smoke
"@ | Set-Content -LiteralPath $Path -NoNewline
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $validator -Path $Path
    $script:lastValidatorExitCode = $LASTEXITCODE
}

function Assert-Passes {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [scriptblock] $Action
    )

    $script:lastValidatorExitCode = $null
    & $Action
    if ($script:lastValidatorExitCode -ne 0) {
        throw "$Name should have passed."
    }
    Write-Output "$Name passed."
}

function Assert-Fails {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [scriptblock] $Action
    )

    $script:lastValidatorExitCode = $null
    & $Action
    if ($script:lastValidatorExitCode -eq 0) {
        throw "$Name should have failed."
    }
    Write-Output "$Name failed as expected."
}

Push-Location $root
try {
    $validPath = New-TempRecordPath
    Write-Record -Path $validPath -GoogleOAuthAvailable "yes" -CalAIHealthState "unknown"
    Assert-Passes "valid record" { Invoke-Validator -Path $validPath }

    $invalidChoicePath = New-TempRecordPath
    Write-Record -Path $invalidChoicePath -GoogleOAuthAvailable "maybe" -CalAIHealthState "sometimes"
    Assert-Fails "invalid preflight choices" { Invoke-Validator -Path $invalidChoicePath }

    $missingScreenshotEvidencePath = New-TempRecordPath
    Write-Record -Path $missingScreenshotEvidencePath -GoogleOAuthAvailable "yes" -CalAIHealthState "unknown" -ScreenshotsCaptured "no"
    Assert-Fails "missing screenshot evidence" { Invoke-Validator -Path $missingScreenshotEvidencePath }

    $mismatchedCandidatePath = New-TempRecordPath
    Write-Record -Path $mismatchedCandidatePath -GoogleOAuthAvailable "yes" -CalAIHealthState "unknown" -CandidateCommit "1111111 Release candidate"
    Assert-Fails "mismatched candidate evidence" { Invoke-Validator -Path $mismatchedCandidatePath }

    $generatedPath = New-TempRecordPath
    & $generator -OutputPath $generatedPath | Out-Null
    Assert-Fails "generated incomplete record" { Invoke-Validator -Path $generatedPath }
} finally {
    Remove-TempRecords
    Pop-Location
}

Write-Output "V1 acceptance tooling smoke passed."
